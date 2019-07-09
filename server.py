from flask import Flask, request, jsonify
import os
from fontTools.ttLib import TTFont
from fontTools.pens.recordingPen import RecordingPen


def get_glyph(glyph_set, cmap, char):
    glyph_name = cmap.get(ord(char), None)
    if glyph_name:
        return glyph_set[glyph_name]


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
    # ここにモデルに投げるコードが入る
    # test_chars = phrase[:3]
    paths = []

    shape = shape_dict.get(phrase[0], 0)
    if shape:
        phrase = phrase[1:(3 if shape not in {3, 4} else 4)]

    for char in phrase:
        recording_pen = RecordingPen()
        glyph = get_glyph(glyph_set, cmap, char)
        if glyph:
            glyph.draw(recording_pen)
            paths.append(recording_pen.value)

    return jsonify({"shape": shape, "paths": {i: {"path": path} for i, path in enumerate(paths)}})


if __name__ == '__main__':
    port = int(os.getenv('PORT', 2036))
    app.run(host='0.0.0.0', port=port, debug=True)
