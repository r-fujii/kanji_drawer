from flask import Flask, request, jsonify
import os
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen


def get_glyph(glyph_set, cmap, char):
    glyph_name = cmap.get(ord(char), None)
    if glyph_name:
        return glyph_set[glyph_name]


def get_model_output(phrase):
    # ここにモデルに投げるコード
    # 暫定的に'タピオカ'に対して'⿰女甘'を出力, それ以外はそのまま返す
    if phrase == 'タピオカ':
        seq = '⿰女甘'
    else:
        seq = phrase
    return seq


# settings
font = TTFont('/System/Library/Fonts/ヒラギノ明朝 ProN.ttc', fontNumber=0)
glyph_set = font.getGlyphSet()
cmap = font.getBestCmap()
shape_dict = {chr(i + ord('⿰')): i+1 for i in range(10)}

app = Flask(__name__)


@app.route('/')
def index():
    return 'hello'


@app.route('/post', methods=['POST'])
def post():
    phrase = request.form['data']
    seq = get_model_output(phrase)
    paths = []

    shape = shape_dict.get(seq[0], 0)
    if shape:
        # TODO: 入れ子の考慮
        seq = seq[1:(3 if shape not in {3, 4} else 4)]

    for char in seq:
        recording_pen = RecordingPen()
        glyph = get_glyph(glyph_set, cmap, char)
        if glyph:
            glyph.draw(recording_pen)
            paths.append(recording_pen.value)

    return jsonify({"shape": shape, "paths": {i: {"path": path} for i, path in enumerate(paths)}})


if __name__ == '__main__':
    port = int(os.getenv('PORT', 2036))
    app.run(host='0.0.0.0', port=port, debug=True)
