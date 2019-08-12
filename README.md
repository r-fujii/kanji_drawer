kanji_generator
====

## Description
入力されたフレーズに近い意味の一漢字を生成し表示するiOSアプリケーションです。  
モデルの学習には、オンラインの漢和辞典および二次熟語データから取得した常用漢字およびそれらにより構成される二次熟語の意味と、漢字の構成に関するデータを使用しています。アーキテクチャはLSTM-based seq2seqモデルを用い偏、旁の独立に学習した2モデルの出力を受け取り漢字を組み立てます。
UIはSwift、モデルおよびjsonデータのやりとりを行うサーバ部分はPythonで記述されており、モデルにはseq2seqのツール(fairseq)を利用しています。

## How to
python server_fairseq_{hen/tukuri}.py ${DICT_DIR} ${CHECKPOINT_PATH} --beam 6 --nbest 6 --cpu  
Please rewrite hostname in ViewController.swift to the name of machine where you run python servers

## Demo

![Movie](https://github.com/r-fujii/kanji_drawer/blob/media/kanji_generator.gif)

## Author

[r-fujii](https://github.com/r-fujii)
