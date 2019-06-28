//  ChatViewController.swift
//  ChatApp
//
//  Created by 西谷恭紀 on 2019/06/09.
//  Copyright © 2019 西谷恭紀. All rights reserved.
//

import UIKit
import MessageKit
import AVFoundation
import InputBarAccessoryView
import Firebase
//import FirebaseStorage
//import FirebaseUI
//import SDWebImage

/*
 UIViewControllerを消してMessagesViewControllerを
 入れることでMessageKitのUIを使えるようになる
 */
class ChatViewController: MessagesViewController {
    
    @IBOutlet var gorillaSwitch: UISwitch!                         //UISWITCHの権限
    @IBOutlet var chatRoomTtitle: UINavigationItem!
    //外部のファイルから書き換えられないようにprivate
    private var ref: DatabaseReference!                            //RealtimeDatabaseの情報を参照
    private var user: User!                                        //ユーザ情報
    private var handle: DatabaseHandle!                            //オブザーバーの破棄を適切にする処理
    var messageList: [Message] = []                                //Message型のオブジェクトの入る配列
    var sendData: [String: Any] = [:]                              //Realtimeデータベースに書き込む内容を格納する辞書
    var readData: [[String: Any]] = []                             //RealtimeDatabaseからの読み込み
    var deleteData: [[String: Any]] = []
    var img: UIImage!                                              //Select画面で選んだゴリラをチャット側でもってくる
    var switchGorillaAudioPlayer: AVAudioPlayer = AVAudioPlayer()  //GORILLAMODEのSOUND
    var switchHumanAudioPlayer: AVAudioPlayer = AVAudioPlayer()    //HUMANMODEのSOUND
    var sendGorillaAudioPlayer: AVAudioPlayer = AVAudioPlayer()    //GORILLAMODEの際の送信音
    var sendHumanAudioPlayer: AVAudioPlayer = AVAudioPlayer()      //HUMANMODEの際の送信音
    let dateFormatter:DateFormatter = DateFormatter()              //日時のフォーマットを管理するもの
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //GORILLAMODEの音セット
        switchGorillaSound()
        sendGorillaSound()
        switchHumanSound()
        sendHumanSound()
        
        //データベースを生成して参照情報をインスタンス化
        ref = Database.database().reference()   //リファレンス(参照)の初期化
        user = Auth.auth().currentUser          //ユーザー認証した現在のユーザーを格納
        
        //GORILLA SWITCH デフォルトでON
        switchGorilla(gorillaSwitch) //初期値ONで"GORILLA MODE
        print("最初のUISwitchは\(gorillaSwitch.isOn)")
        chatRoomTtitle.title = "G O R I L L A  M O D E"
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
        
        //各種デリゲートをこのVCに設定(拡張機能)
        //messagesCollectionViewはチャット画面の中の各ユーザーメッセージのデータの塊
        //各機能が備わっているデリケードをChatViewControllerで使えるように定義している
        //先に書くとエラーがでるが､拡張機能の追加で消える
        //データの扱い
        messagesCollectionView.messagesDataSource = self as MessagesDataSource
        //レイアウト
        messagesCollectionView.messagesLayoutDelegate = self as MessagesLayoutDelegate
        //ディスプレイ
        messagesCollectionView.messagesDisplayDelegate = self as MessagesDisplayDelegate
        //Cellの扱い方
        messagesCollectionView.messageCellDelegate = self as MessageCellDelegate
        //文字入力の部分
        messageInputBar.delegate = self as InputBarAccessoryViewDelegate
        
        // メッセージ入力が始まった時に一番下までスクロールする
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        // 表示している画面とキーボードの重複を防ぐ
        maintainPositionOnKeyboardFrameChanged = true // default false
        
        //DateFormatter()で日付と時刻と地域を指定(今回は日本時間を指定)
        dateFormatter.dateStyle = .medium //日付の表示スタイルを決定
        dateFormatter.timeStyle = .short  //時刻の表示スタイルを決定
        dateFormatter.locale = Locale(identifier: "ja_JP")//地域を決定
        
    }
    
    //viewが表示される直前に呼ばれるメソッド
    override func viewWillAppear(_ animated: Bool) {
        updateViewWhenMessageAdded()
    }
    
    //viewが表示されなくなる直前に呼び出されるメソッド
    override func viewWillDisappear(_ animated: Bool) {
        ref.child("chats").removeObserver(withHandle: handle)
    }
    
    //MODEの切り替え
    @IBAction func switchGorilla(_ sender: UISwitch) {
        //sender.isOnのみに省略可能
        switch gorillaSwitch.isOn {
        case true:
            messageInputBar.sendButton.title = "ウホッ"
            self.switchGorillaAudioPlayer.play()
            chatRoomTtitle.title = "G O R I L L A  M O D E"
            displayMessageGorilla()
            print("GORILLA MODE \(gorillaSwitch.isOn)")
        default:
            messageInputBar.sendButton.title = "Send"
            self.switchHumanAudioPlayer.play()
            chatRoomTtitle.title = "H U M A N  M O D E"
            displayMessageHuman()
            print("GORILLA MODE \(gorillaSwitch.isOn)")
        }
    }
    
    //RealtimeDatabaseに書き込みをする際の処理(JSONだと読みやすい)
    //Firebaseにチャット内容を保存するためのメソッド
    //Firebaseに送りたい情報は今回はテキスト
    func sendMessageToFirebase(text: String){
        if !sendData.isEmpty {sendData = [:] } //辞書の初期化(送信データの中身がからじゃなければ空にする)
        let sendRef = ref.child("chats").childByAutoId()    //自動生成の文字列の階層までのDatabaseReferenceを格納
        let messageId = sendRef.key! //自動生成された文字列(AutoId)を格納
        let resultWords = Int( arc4random_uniform(UInt32(GorillaLanguage().gorilla.count)) )
        let resultName = Int( arc4random_uniform(UInt32(GorillaName().gorillaName.count)) )
        print("sendRefの中身\n\(sendRef)")
        print("messageIdの中身\n\(messageId)")
        
        //これがJSON(書き方のルール的な)
        sendData = ["senderName": user?.displayName,//送信者の名前
            "senderId": user?.uid,          //送信者のID
            "content": text,                //送信内容（今回は文字のみ）
            "gorilla": GorillaLanguage().gorilla[resultWords],
            "gorillaName": GorillaName().gorillaName[resultName],
            "createdAt": dateFormatter.string(from: Date()),//送信時刻
            "messageId": messageId //送信メッセージのID
        ]
        sendRef.setValue(sendData) //ここで実際にデータベースに書き込んでいます
    }
    
    
    //データベースから読み込んだデータを配列(readData)に格納するメソッド
    func snapshotToArray(snapshot: DataSnapshot){
        //中身を0にする
        if !readData.isEmpty {readData = [] }
        //スナップショットとは、ある時点における特定のデータベース参照にあるデータの全体像を写し取ったもの
        if snapshot.children.allObjects as? [DataSnapshot] != nil  {
            let snapChildren = snapshot.children.allObjects as? [DataSnapshot]
            //snapChildrenの中身の数だけsnapChildをとりだす
            for snapChild in snapChildren! {
                //要素を追加していく
                //snapChildのvalueに値があったらreadDataに追加していく
                if let postDict = snapChild.value as? [String: Any] {
                    self.readData.append(postDict)
                }
            }
        }
    }
    
    //メッセージの画面表示に関するメソッド
    //HUMAN_MODE
    func displayMessageHuman() {
        //メッセージリストを初期化
        if !messageList.isEmpty {messageList = []}
        
        for itemHuman in readData {
            print("Humanitem: \(itemHuman)\n")
            let message = Message(
                sender: Sender(id: itemHuman["senderId"] as! String,displayName: itemHuman["senderName"] as! String),
                messageId: itemHuman["messageId"] as! String,
                sentDate: self.dateFormatter.date(from: itemHuman["createdAt"] as! String)!,
                kind: MessageKind.text(itemHuman["content"] as! String)
            )
            messageList.append(message)
        }
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    //GORILLA_MODE
    func displayMessageGorilla() {
        //メッセージリストを初期化
        if !messageList.isEmpty {messageList = []}
        
        for itemGorilla in readData {
            print("Gorillaitem: \(itemGorilla)\n")
            let message = Message(
                sender: Sender(id: itemGorilla["senderId"] as! String,displayName: itemGorilla["gorillaName"] as! String),
                messageId: itemGorilla["messageId"] as! String,
                sentDate: self.dateFormatter.date(from: itemGorilla["createdAt"] as! String)!,
                kind: MessageKind.text(itemGorilla["gorilla"] as! String)
            )
            messageList.append(message)
        }
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom()
    }
    
    /*
     ref - Databaseの情報を参照
     .child("chats") - "chats"という名前の階層の下
     .queryLimited(toLast: 25) - 最後から25件を取得
     .queryOrdered(byChild: "createdAt") - 下の階層にある"createdAt"を元に並び替え
     .observe(.value) - valueタイプでオブザーバーをセット
     */
    //メッセージが追加された際に読み込んで画面を更新するメソッド
    func updateViewWhenMessageAdded() {
        //古い順にとって降順にしている
        handle = ref.child("chats").queryLimited(toLast: 500).queryOrdered(byChild: "createdAt").observe(.value) { (snapshot: DataSnapshot) in
            DispatchQueue.main.async {//クロージャの中を同期処理
                self.snapshotToArray(snapshot: snapshot)//スナップショットを配列(readData)に入れる処理。下に定義
                switch self.gorillaSwitch.isOn {
                case true:
                    self.displayMessageGorilla() //メッセージを画面に表示するための処理
                default:
                    self.displayMessageHuman()
                }
            }
        }
    }
    
    //GORILLAMODEのswitch音のセット
    func switchGorillaSound(){
        if let sound = Bundle.main.path(forResource: "GolliraMode", ofType: ".mp3"){
            switchGorillaAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            switchGorillaAudioPlayer.prepareToPlay()
        }
    }
    
    //HUMANMODEのswitch音のセット
    func switchHumanSound(){
        if let sound = Bundle.main.path(forResource: "HUMANMODE2", ofType: ".mp3"){
            switchHumanAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            switchHumanAudioPlayer.prepareToPlay()
        }
    }
    
    //GORILLAMODEのsend音のセット
    func sendGorillaSound(){
        if let sound = Bundle.main.path(forResource: "SendUho1", ofType: ".mp3"){
            sendGorillaAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            sendGorillaAudioPlayer.prepareToPlay()
        }
    }
    
    //HUMANMODEのsend音のセット
    func sendHumanSound(){
        if let sound = Bundle.main.path(forResource: "HUMAN", ofType: ".mp3"){
            sendHumanAudioPlayer = try! AVAudioPlayer(contentsOf: URL(fileURLWithPath: sound))
            sendHumanAudioPlayer.prepareToPlay()
        }
    }

}

//ここから拡張機能↓
/*
 前のクラスと同じ名前を使うことができるが､メソッドを修正することができない為,
 新たなメソッドを作成する必要がある
 */

//MessageDataSourceの拡張

extension ChatViewController: MessagesDataSource {
    //自分の情報を設定
    //currentSender()(現在の画像の送信者)
    func currentSender() -> SenderType {
        //誰?(senderId: user.uid, displayName: user.displayName!)を参照して送信者を決定
        return Sender(senderId: user.uid, displayName: user.displayName!)
    }
    //表示するメッセージの数
    //セクションという1つのまとまりをTableのように扱っている
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    //メッセージの実態(中身)
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        //セクションの中身のメッセージをindexPathで呼び出している
        return messageList[indexPath.section] as MessageType
    }
    
    //セルの上の文字
    //これから表示する文字列の魅せ方(フォントどうするかとか)の設定
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            //属性付きの文字列を作る
            return NSAttributedString(
                //MessageKitの中のDate型を使っている
                string: MessageKitDateFormatter.shared.string(from: message.sentDate),
                //属性(見た目の処理)
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10),
                             NSAttributedString.Key.foregroundColor: UIColor.darkGray]
            )
        }
        return nil
    }
    
    // メッセージの上の文字(送信者の名前)
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        //送信者の名前を取得している
        let name = message.sender.displayName
        //送信者の名前を表示している
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
    
    // メッセージの下の文字(日付)
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        //日時を参照
        let formatter = DateFormatter()
        //日時の情報を全て取得している
        formatter.dateStyle = .full
        let dateString = formatter.string(from: message.sentDate)
        //日時の情報を全て表示している
        return NSAttributedString(string: dateString, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption2)])
    }
    
    
    func showAlert(message: String, handler: ((Bool) -> Void)?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let yesAction: UIAlertAction = UIAlertAction(title: "OK", style: .default){ action in
            if let handler = handler {
                handler(true) // OKを選択したらクロージャでtrueを返す
            }
        }
        let noAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: .cancel){ action in
            if let handler = handler {
                handler(false) // キャンセルを選択したらクロージャでfalseを返す
            }
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true, completion: nil)
    }
}

//MessageDisplayDelegateの拡張
// メッセージの見た目に関するdelegate
extension ChatViewController: MessagesDisplayDelegate {
    
    // メッセージの色を変更
    //三項演算子  条件式(True : False) if文を1行で書くパターンらしい
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        //現在ログインしている人からの情報であるのならばTrue(white)｡違ってたらFalse(darkText)｡
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    // メッセージの背景色を変更している
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        //現在ログインしている人からの情報であるのならばTrue｡違ってたらFalse｡
        return isFromCurrentSender(message: message) ?
            UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1) :
            UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    // メッセージの枠にしっぽ(吹き出しっぽくみせるやつ)を付ける
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        //現在ログインしている人からの情報であるのならば吹き出しっぽくみせるやつをTrue(右に出す)｡違ってたらFalse(左に出す)｡
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }
    
    // アイコンをセット
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // message.sender.displayNameとかで送信者の名前を取得できるので
        // そこからイニシャルを生成するとよい
        // 課題:相手側は相手でアイコンを設定する方法を考える(とりあえず1個の場合はできた)
        let avatar = Avatar(image: img, initials: message.sender.displayName)
        avatarView.set(avatar: avatar)
    }
}

//MessageLayoutDelegateの拡張
// 各ラベルの高さを設定（デフォルト0なので必須）、メッセージの表示位置に関するデリゲート
extension ChatViewController: MessagesLayoutDelegate {
    
    //cellTopLabelAttributedTextを表示する高さ
    //Cellの上の方に表示する高さはどれくらいにするか
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        //現在位置からは10放している
        if indexPath.section % 3 == 0 { return 10 }
        return 0
    }
    
    //messageTopLabelAttributedTextを表示する高さ
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
    
    //messageBottomLabelAttributedTextを表示する高さ
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 16
    }
}

//MessageCellDelegateの拡張
extension ChatViewController: MessageCellDelegate {
    
    // メッセージをタップした時の挙動
    func didTapMessage(in cell: MessageCollectionViewCell) {
        //
        let indexPath = messagesCollectionView.indexPath(for: cell)
        //
        let messageData = messageList[(indexPath?.section)!]
        //消したいメッセージIDをとりたい
        let deleteMessageId = messageData.messageId
        
        //アラートの内容を定義
        if messageData.sender.senderId == Auth.auth().currentUser?.uid {
            let alert = UIAlertController(title: "削除", message: "このメッセージを削除しますか？", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title:"キャンセル", style: .cancel)
            //アラートに追加するアクションを定義
            //.destructiveで文字を赤くする
            let deleteAction = UIAlertAction(title: "削除する", style: .destructive, handler: { (action) in
                //削除処理
                self.ref.child("chats").child(deleteMessageId).removeValue()
                
            })
            //アラートを発報
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            
            //データの選択されたIDと現在のログインしているユーザのIDが一致した場合のみ削除できる
            if messageData.sender.senderId == Auth.auth().currentUser?.uid{
                present(alert, animated: true)
            }
        }
    }
}

//InputAccessoryViewDelegateの拡張
extension ChatViewController: InputBarAccessoryViewDelegate {
    // メッセージ送信ボタンを押されたとき
    // inputBar(textField)についている送信ボタンを押したとき
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        //Firebaseに送信するメソッド
        sendMessageToFirebase(text: text)
        //inputBarの中のテキストを表示して
        inputBar.inputTextView.text = ""
        //GORILLA MODEの時だけSEND音を鳴らす
        if gorillaSwitch.isOn{
            sendGorillaAudioPlayer.play()
        }else{
            sendHumanAudioPlayer.play()
        }
        
        //一番下までスクロールしている
        messagesCollectionView.scrollToBottom()
        print("messageList when sendButton pressed:\(messageList)")
        print("messageList when sendButton pressed:\(Message.self)")
    }
}
