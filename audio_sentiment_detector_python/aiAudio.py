import glob
import os
from collections import Counter
from pathlib import Path

import librosa
import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow.keras.initializers import glorot_uniform
import shutil

labels = ["neutral", "calm", "happy", "sad", "angry", "fearful", "disgust", "surprised", ]
loaded_model = tf.keras.models.load_model("Data_noiseNshift.h5",
                                          custom_objects={'GlorotUniform': glorot_uniform()})
print("Loaded model from disk")

# evaluate loaded model on test data
loaded_model.compile(loss='categorical_crossentropy', optimizer='adam', metrics=['accuracy'])


def mkdir(name):
    if not os.path.exists(name):
        os.mkdir(name)

def remove_dir(path):
    if os.path.exists(path):
        shutil.rmtree(path)

input_duration = 3.48


def split_audio(audio_path):
    filename = Path(audio_path).stem

    mkdir(filename)
    # split audio by 3 seconds
    os.popen(
        f'ffmpeg -i "{audio_path}" -f segment -segment_time {input_duration} -c copy "{filename}/audio%03d.wav"').read()
    return filename


def predictions(folder):
    filenames = glob.glob(f"{folder}/*.wav")

    data_test = pd.DataFrame(columns=['feature'])
    for i in range(len(filenames)):
        X, sample_rate = librosa.load(filenames[i], res_type='kaiser_fast', duration=input_duration, sr=22050 * 2,
                                      offset=0.5)
        #     X = X[10000:90000]
        sample_rate = np.array(sample_rate)
        mfccs = np.mean(librosa.feature.mfcc(y=X, sr=sample_rate, n_mfcc=13), axis=0)
        feature = mfccs
        data_test.loc[i] = [feature]

    test_valid = pd.DataFrame(data_test['feature'].values.tolist())
    test_valid = np.array(test_valid)
    test_valid = np.expand_dims(test_valid, axis=2)
    preds = loaded_model.predict(test_valid,
                                 batch_size=16,
                                 verbose=1)
    return preds


def fetch_prediction(audio_file):
    folder = split_audio(audio_file)
    preds = predictions(folder)
    preds = preds.argmax(axis=1)

    pred = Counter(preds).most_common()[0][0]
    label = labels[pred]
    remove_dir(folder)
    return label


# print(fetch_prediction('Voices For Fun： Three old lady voices.wav'))
