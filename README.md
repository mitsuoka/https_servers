https_servers
==

**https_servers** is a Dart sample HTTPS server applications.

This is a Dart code sample and an attachment to the ["Dart Language Gide"](http://www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide.pdf) written in Japanese.

This repository consists of following source codes.

- **https\_test\_server\_1.dart** : Simple HTTPS test server.

- **https\_test\_server\_2.dart** : Simple HTTPS server. Can be used as a template for HTTPS servers.

このサンプルは「["プログラミング言語Dartの基礎"](http://www.cresc.co.jp/tech/java/Google_Dart/DartLanguageGuide_about.html)」の 添付資料です。詳細は「HTTPSサーバ (HTTPS Servers)」の章をご覧ください

### Installing ###

1. Download this repository, uncompress and rename the folder to **https_servers**.
2. From Dart Editor, File > Open Existing Folder and select this https_servers folder.

### Try it ###

1. Run **bin/https\_test\_server\_1.dart** or **bin/https\_test\_server\_2.dart** as server.
2. Access these servers from your browser as `https://localhost/test`.


### Notes ###

1. This program runs on **Dart-SDK 1.13.0 dev 1.0** or later.
2. Tested on Windows.
3. Attached OpenSSL holder includes self-signed certificate. Your browser will complain about certificate is not valid.
4. Other than on Windows, you may need to change the path-to-pem file path value.

### License ###
This sample is licensed under [MIT License][MIT].
[MIT]: http://www.opensource.org/licenses/mit-license.php