import os

from flask import Flask, request, jsonify

from aiAudio import fetch_prediction

app = Flask(__name__)


@app.route("/")
def home():
    return "<h1>Music Analyzer page</h1>"


@app.route('/fetch_prediction', methods=['POST'])
def generate_default_audio():
    if request.method == 'POST':
        f = request.files['audio']
        filename = f.filename
        f.save(filename)
        path_to_file = fetch_prediction(filename)
        print(path_to_file)
        os.remove(filename)
        return jsonify(path_to_file)


app.run(host='0.0.0.0')
