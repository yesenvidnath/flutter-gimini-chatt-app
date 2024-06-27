import "package:flutter/material.dart";
// import "package:flutter/rendering.dart";
import "package:giminichatapp/message_widget.dart";
import "package:google_generative_ai/google_generative_ai.dart";
// import "package:flutter_markdown/flutter_markdown.dart";

class HomeScreen extends StatefulWidget{
  const HomeScreen ({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState(); 
}

class _HomeScreenState extends State<HomeScreen>{
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final FocusNode _textFileldFocus = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController= ScrollController();

  //adding handler forthe loading 
  bool _loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _model = GenerativeModel(
      model: 'gimini-pro', apiKey: const String.fromEnvironment('api_key'),
    );
    _chatSession = _model.startChat();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build ith Gimini'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _chatSession.history.length,
                itemBuilder: (context, index) {
                  final Content content = _chatSession.history.toList()[index];
                  final text = 
                      content.parts.whereType<TextPart>().map<String>((e) => e.text ).join('');
                  return MessageWidget(
                    text: text, 
                    isFromUser: content.role == 'user',
                  );
              },),
            ),

            Padding(
              padding: EdgeInsets.symmetric(
                vertical: 25,
                horizontal: 15,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: true,
                      focusNode: _textFileldFocus,
                      decoration: textFieldDecoration(),
                      controller: _textController,
                      onSubmitted: _sendChatMessage,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Decoration input feelds and buttons
  InputDecoration textFieldDecoration(){
    return InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter Your Mind ... ',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ), 
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder:  OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color:Theme.of(context).colorScheme.secondary, 
        ),
      ),
    );
  }

  // Decorations of text fealds 
  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try{
      final response = await _chatSession.sendMessage( 
        Content.text(message),
      );
      final text = response.text;
      if (text == null) {
        _showError('No responce from API.');
        return;
      } else{
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    }catch(e){
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    }finally{
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFileldFocus.requestFocus();
    }
  }



 // Scroll Screen to the bottom after response 

 void _scrollDown() {
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(
        milliseconds: 750,
      ),
      curve: Curves.easeOutCirc,
    ),
  );
 }

  // Display error 
  void _showError(String message) {
    showDialog<void>(
      context: context, 
      builder: (context) {
        return AlertDialog(
          title: const Text('oops something went Wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              }, 
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}