import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/Screens/About_Page_Screen.dart';
import 'package:flutter_app/Gift_Card.dart';
import '../Databases/Gift_Card_Database.dart';
import 'package:flutter_app/Notification_Plugin.dart';
import 'Card_Info_Screen.dart';
import 'package:flutter_app/Screens/Create_New_Card_Screen.dart';

/// Home screen of the app.
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      title: 'Add or View Saved Cards',
      home: HomeScreenState(title: 'Add or View Saved Cards'),
    );
  }
}

class HomeScreenState extends StatefulWidget {
  HomeScreenState({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomeScreenState createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<HomeScreenState> {
  /// The list of the current gift cards.
  List<GiftCard> giftCards = [];

  /// The list of gift card widgets, created by calling the [seeGiftCardButton]
  /// method for each item in the [giftCards].
  List<Widget> get giftCardWidgets =>
      giftCards.map((item) => seeGiftCardButton(item)).toList();

  _MyHomeScreenState();

  /// Sets up the initial state for the [HomeScreen] widget.
  @override
  void initState() {
    // Retrieves the gift cards that are currently in the database when the user opens the app.
    _setUpGiftCards();

    // Sets the initial state of the widget.
    super.initState();
  }

  /// Adds in our special gray color so it is easier to user later on.
  Color specialGrey = Color.fromRGBO(174, 174, 174, 1.0);

  /// Builds the [HomeScreen].
  ///
  /// The contents of the [HomeScreen] are defined by whether there are gift
  /// cards stored or not.
  @override
  Widget build(BuildContext context) {
    Widget content;
    if (giftCards.isNotEmpty) {
      content = setUpNotEmptyList(context);
    } else {
      content =  setUpEmptyList(context);
    }
    return Scaffold(
        resizeToAvoidBottomPadding: false,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text("Add or View Saved Cards", style: TextStyle(color: Colors.white, fontSize: 20.0)),
          centerTitle: true,
          backgroundColor: Color.fromRGBO(32, 32, 48, 1.0),
          leading: IconButton(
            icon: Icon(CupertinoIcons.info, color: Colors.white,),
            onPressed: () {_goToAbout(context);},
          ),
        ),

        body: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.fromRGBO(53, 51, 81, 1.0), Color.fromRGBO(21, 21, 25, 1.0)])
            ),
            child: content
        )
    );
  }

  /// Builds the home screen given there are no gift cards stored.
  Widget setUpEmptyList(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: <Widget>[
          Expanded(
            child : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 0.0),
                  child: Image(
                      image: AssetImage("assets/emptywallet.png")
                  ),
                ),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                    child: Text(
                      "You don't have any gift cards yet!",
                      style: TextStyle(fontSize: 24, color: specialGrey), textAlign: TextAlign.center,
                    )
                ),
                Container(
                    padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                    child: Text(
                      "Press the add button to get started!",
                      style: TextStyle(fontSize: 24, color: specialGrey), textAlign: TextAlign.center,
                    )
                ),
              ],
            ),
          ),
          buildAddButton()
        ]
    );
  }


  /// Builds the [HomeScreen] given there are gift cards stored.
  Widget setUpNotEmptyList(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: giftCardWidgets),
          ),
          buildAddButton()
        ]
    );
  }

  /// Returns a button that when clicked, goes to the [CreateNewCardScreen].
  Widget buildAddButton(){
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          backgroundColor: Color.fromRGBO(105, 180, 233, 1.0),
          child: Icon(Icons.add),
          onPressed: () {
            _getGiftCardInfo(context);
          },
        ),
      ],
    );
  }

  /// Returns a card that, when clicked, goes to the [CardInfoScreen].
  Widget seeGiftCardButton(GiftCard card) {
    return Card(
        color: specialGrey,
        child: ListTile(
          onTap: () {
            _modifyGiftCard(context, card);
          },
          title: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 50, minHeight: 50),
              child: FittedBox(
                  child: Text(
                      card.name,
                      style: TextStyle(fontSize: 24, color: Colors.black87)
                  )
              )
          ),
          leading: card.photo != null ? Image.file(File(card.photo)) : Image(image: AssetImage("assets/defaultgiftcard.png")),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text(
                'Balance: ' + card.balance,
                style: TextStyle(fontSize: 14, color: Colors.black38),
              ),
              Text(
                'Exp: ' + card.expirationDate,
                style: TextStyle(fontSize: 14, color: Colors.black38),
              )
            ],
          ),
        ));
  }

  /// Updates the list of [giftCards] when there is a new card is added, or an
  /// existing card is edited or deleted.
  ///
  /// Gets all the cards currently stored in the [Database], and maps all of
  /// them to the [giftCards] list. After it, the notifications and the widget
  /// get updated.
  _setUpGiftCards() async {
    List<Map<String, dynamic>> _results = await DB.query(GiftCard.table);
    giftCards = _results.map((item) => GiftCard.fromMap(item)).toList();
    _setUpNotifications();
    setState(() {});
  }

  /// Sets up the notifications, based on the current [giftCards].
  ///
  /// Cancels all the previous notifications, and then adds a weekly notification
  /// and a scheduled notification for each [giftCard]. Cancelling all previous
  /// notifications is necessary in order to handle changes when a gift card is
  /// edited or deleted.
  _setUpNotifications() async {
    await notificationPlugin.cancelAllNotifications();
    await notificationPlugin.setOnNotificationClick(_onNotificationClick);;
    if(giftCards.length != 0){
      await notificationPlugin.sendWeeklyNotification();

      for (GiftCard giftCard in giftCards) {
        await notificationPlugin.sendScheduledNotifications(giftCard);
      }
    }
  }

  /// Handles changes in the screen when a [card] is deleted or edited in the
  /// [CardInfoScreen].
  _modifyGiftCard(BuildContext context, GiftCard card) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => CardInfoScreen(card)));
    _setUpGiftCards();
  }

  /// Handles going to the [AboutScreen]
  _goToAbout(BuildContext context) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => AboutPageScreen()));
  }

  /// Manipulates the information the user entered in the [CreateNewCardScreen].
  ///
  /// Converts the [result] of the [CreateNewCardScreen] into a [GiftCard]
  /// object named [card], and, if the [card] is not null, it is added to the
  /// [Database]. Then, the [_setUpGiftCards] method is called to update the
  /// contents of the [giftCards] list.
  _getGiftCardInfo(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateNewCardScreen()),
    );

    GiftCard card = result;

    if (card != null) {
      await DB.insert(GiftCard.table, card);
      _setUpGiftCards();
    }
  }

  /// Opens the [HomeScreen] when a notification is clicked.
  _onNotificationClick() {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return build(context);
    }));
  }
}


