from flask import Flask, request, jsonify
import os
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen
from logzero import logger

### from fairseq interactive
from collections import namedtuple
import torch
import numpy as np
from fairseq import data, options, tasks, tokenizer, utils
from fairseq.sequence_generator import SequenceGenerator
from fairseq.utils import import_user_module
###

Batch = namedtuple('Batch', 'srcs tokens lengths')
Translation = namedtuple('Translation', 'src_str hypos attention pos_scores')


def make_batches(lines, task, max_positions):
    tokens = [
        tokenizer.Tokenizer.tokenize(src_str, task.source_dictionary, add_if_not_exist=False).long()
        for src_str in lines
    ]
    lengths = np.array([t.numel() for t in tokens])
    itr = task.get_batch_iterator(
        dataset=data.LanguagePairDataset(tokens, lengths, task.source_dictionary),
        max_tokens=None,
        max_sentences=None,
        max_positions=max_positions,
    ).next_epoch_itr(shuffle=False)
    for batch in itr:
        yield Batch(
            srcs=[lines[i] for i in batch['id']],
            tokens=batch['net_input']['src_tokens'],
            lengths=batch['net_input']['src_lengths'],
        ), batch['id']


def setup_model(args):
    import_user_module(args)

    if args.buffer_size < 1:
        args.buffer_size = 1
    if args.max_tokens is None and args.max_sentences is None:
        args.max_sentences = 1

    assert not args.sampling or args.nbest == args.beam, \
        '--sampling requires --nbest to be equal to --beam'
    assert not args.max_sentences or args.max_sentences <= args.buffer_size, \
        '--max-sentences/--batch-size cannot be larger than --buffer-size'

    logger.info('fairseq args: {}'.format(args))

    # Setup task, e.g., translation
    task = tasks.setup_task(args)

    # Load ensemble
    logger.info('| loading model(s) from {}'.format(args.path))
    models, _model_args = utils.load_ensemble_for_inference(
        args.path.split(':'), task, model_arg_overrides=eval(args.model_overrides),
    )

    # Set dictionary
    tgt_dict = task.target_dictionary

    # Optimize ensemble for generation
    for model in models:
        model.make_generation_fast_(
            beamable_mm_beam_size=None if args.no_beamable_mm else args.beam,
            need_attn=args.print_alignment,
        )

    translator = SequenceGenerator(
        models, tgt_dict, beam_size=args.beam, minlen=args.min_len,
        stop_early=(not args.no_early_stop), normalize_scores=(not args.unnormalized),
        len_penalty=args.lenpen, unk_penalty=args.unkpen,
        sampling=args.sampling, sampling_topk=args.sampling_topk, sampling_temperature=args.sampling_temperature,
        diverse_beam_groups=args.diverse_beam_groups, diverse_beam_strength=args.diverse_beam_strength,
        match_source_len=args.match_source_len, no_repeat_ngram_size=args.no_repeat_ngram_size,
    )

    if torch.cuda.is_available() and not args.cpu:
        translator.cuda()

    logger.info('model has been read successfully!')
    return models, task, tgt_dict, translator


def make_result(src_str, hypos, tgt_dict, nbest=6):
    result = Translation(
        src_str=src_str,
        hypos=[],
	attention=[],
        pos_scores=[],
    )

    # Process top predictions
    for i, hypo in enumerate(hypos[:min(len(hypos), nbest + 1)], start=1):
        hypo_tokens, hypo_str, alignment = utils.post_process_prediction(
            hypo_tokens=hypo['tokens'].int().cpu(),
            src_str=src_str,
            alignment=hypo['alignment'].int().cpu() if hypo['alignment'] is not None else None,
            align_dict=None,
            tgt_dict=tgt_dict,
            remove_bpe=None,
        )
        result.hypos.append((hypo['score'], '{}'.format(hypo_str)))
        att_weights = torch.t(hypo['attention'])[0].tolist()
        result.attention.append(att_weights)
        result.pos_scores.append('P\t{}'.format(
            ' '.join(map(
                lambda x: '{:.4f}'.format(x),
                hypo['positional_scores'].tolist(),
            ))
        ))

    return result


def process_batch(translator, batch, tgt_dict):
    tokens = batch.tokens
    lengths = batch.lengths

    if torch.cuda.is_available() and not args.cpu:
        tokens = tokens.cuda()
        lengths = lengths.cuda()

    encoder_input = {'src_tokens': tokens, 'src_lengths': lengths}
    translations = translator.generate(
        encoder_input,
        maxlen=int(args.max_len_a * tokens.size(1) + args.max_len_b),
    )

    return [make_result(batch.srcs[i], t, tgt_dict) for i, t in enumerate(translations)]


def get_glyph(glyph_set, cmap, char):
    glyph_name = cmap.get(ord(char), None)
    if glyph_name:
        return glyph_set[glyph_name]


def get_model_output(phrase, models, task, tgt_dict, translator):
    max_positions = utils.resolve_max_positions(
        task.max_positions(),
        *[model.max_positions() for model in models]
    )

    indices = []
    results = []

    for batch, batch_indices in make_batches(phrase, task, max_positions):
        indices.extend(batch_indices)
        results += process_batch(translator, batch, tgt_dict)

    result = results[0]
    return [(hypo, att) for hypo, att in zip(result.hypos, result.attention)]


# settings
font = TTFont('./ヒラギノ明朝 ProN.ttc', fontNumber=0)
glyph_set = font.getGlyphSet()
cmap = font.getBestCmap()

app = Flask(__name__)


@app.route('/')
def index():
    return 'hello'


@app.route('/post', methods=['POST'])
def post():
    phrase = request.form['data']
    logger.info('got post request from app: phrase = "{}"'.format(phrase))
    seqs = get_model_output([' '.join(list(phrase))], models, task, tgt_dict, translator)
    logger.info('receieved model output')
    paths = []

    scores = [seq[0][0] for seq in seqs]
    att_weights = [seq[1] for seq in seqs]
    seqs = [seq[0][1][0] for seq in seqs]

    print('----- candidates -----')
    for seq in seqs:
        print(seq)

    print('----- attention weights -----')
    for c, w in zip(phrase, att_weights[0][:-1]):
         print('{}: {}'.format(c, w))

    for seq in seqs:
        recording_pen = RecordingPen()
        glyph = get_glyph(glyph_set, cmap, seq)
        if glyph:
            glyph.draw(recording_pen)
            paths.append(recording_pen.value)

    logger.info('return kanji path data to app')
    return jsonify({"paths": {rank: {"char": char, "score": score, "attention": att, "path": path} for rank, (char, score, att, path) in enumerate(zip(seqs, scores, att_weights, paths), start=1)}})


if __name__ == '__main__':
    # 内部的にはargparse
    parser = options.get_generation_parser(interactive=True)
    args = options.parse_args_and_arch(parser)

    models, task, tgt_dict, translator = setup_model(args)

    port = int(os.getenv('PORT', 2036))
    app.run(host='0.0.0.0', port=port, debug=True)
