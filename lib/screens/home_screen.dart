

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_downloader/image_downloader.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:text_to_speech/text_to_speech.dart';
import 'package:va_bot/api/api_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  TextEditingController userInputTextEditingController = TextEditingController();
  final SpeechToText speechToTextInstance = SpeechToText();
  String recordedAudioString = "";
  bool isLoading = false;
  bool speakLOCAL = true;
  String modeOpenAI = "chat";
  String imageUrlFromOpenAI = "";
  String answerTextFromOpenAI = "";
  final TextToSpeech textToSpeechInstance = TextToSpeech();

  void initializeSpeechToText() async {
    await speechToTextInstance.initialize();
    setState(() {});
  }

  void startListeningNow() async {
    FocusScope.of(context).unfocus();
    await speechToTextInstance.listen(onResult: onSpeechToTextResult);
    setState(() {});
  }

  void stopListeningNow() async {
    await speechToTextInstance.stop();
    setState(() {});
  }

  void onSpeechToTextResult(SpeechRecognitionResult recognitionResult) {
    recordedAudioString = recognitionResult.recognizedWords;
    setState(() {});

    if (!speechToTextInstance.isListening) {
      sendRequestToOpenAI(recordedAudioString);
    }

    print("Speech Result:");
    print(recordedAudioString);
  }

Future<void> sendRequestToOpenAI(String userInput) async {
  stopListeningNow();

  setState(() {
    isLoading = true;
  });

  // send the request to OpenAI using our APIService
  await APIService().requestOpenAI(userInput, modeOpenAI, 2000).then((value) {
    setState(() {
      isLoading = false;
    });

    if (value.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("API Key you were using expired or it is not working anymore"),
        ),
      );
    }

    userInputTextEditingController.clear();

    final responseAvailable = jsonDecode(value.body);

    print("OpenAI API Response:");
    print(responseAvailable);

    if (modeOpenAI == "chat") {
      setState(() {
        if (responseAvailable != null &&
            responseAvailable.containsKey("choices") &&
            responseAvailable["choices"] is List &&
            responseAvailable["choices"].isNotEmpty &&
            responseAvailable["choices"][0] is Map &&
            responseAvailable["choices"][0].containsKey("text")) {
          answerTextFromOpenAI =
              responseAvailable["choices"][0]["text"].toString();

          print("ChatGPT Chatbot: ");
          print(answerTextFromOpenAI);
        } else {
          // Handle the case when the expected data is not available
          answerTextFromOpenAI = "No response available";
        }
      });

      if(speakLOCAL == true)
      {
        textToSpeechInstance.speak(answerTextFromOpenAI);
      }

    } else {
      // image generation
      setState(() {
        if (responseAvailable != null &&
            responseAvailable.containsKey("data") &&
            responseAvailable["data"] is List &&
            responseAvailable["data"].isNotEmpty &&
            responseAvailable["data"][0] is Map &&
            responseAvailable["data"][0].containsKey("url")) {
          imageUrlFromOpenAI = responseAvailable["data"][0]["url"];

          print("Generated Dale E Image Url: ");
          print(imageUrlFromOpenAI);
        } else {
          // Handle the case when the expected data is not available
          imageUrlFromOpenAI = "";
        }
      });
    }

    if (modeOpenAI == "chat") {
      // Check if answerTextFromOpenAI is not empty before updating
      if (answerTextFromOpenAI.isNotEmpty) {
        setState(() {
          answerTextFromOpenAI = answerTextFromOpenAI;
        });
      }
    }

  }).catchError((errorMessage) {
    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: " + errorMessage.toString()),
      ),
    );
  });
}



  @override
  void initState() {
    super.initState();

    initializeSpeechToText();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: ()
        {
          if(!isLoading)
          {
            setState(() {
              speakLOCAL = !speakLOCAL;
            });
          }

          textToSpeechInstance.stop();
        },
        child: speakLOCAL ? Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            "images/sound.png"
          ),
        ) :Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
              "images/mute.png"
          ),
        ) ,
      ),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purpleAccent.shade100,
                Colors.deepPurple,
              ]
            )
          )
        ),
        title: Image.asset(
          "images/logo.png",
            width: 140,
        ),
        titleSpacing: 10,
        elevation: 0,
        actions: [

          //chat
          Padding(
            padding: const EdgeInsets.only(right: 4.0, top: 4),
            child: InkWell(
              onTap: ()
              {
                setState(() {
                  modeOpenAI = "chat";
                });
              },
              child: Icon(
                Icons.chat,
                size: 40,
                color: modeOpenAI == "chat" ? Colors.white : Colors.grey,
              ),
            ),
          ),

          //image
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: InkWell(
              onTap: ()
              {
                setState(() {
                  modeOpenAI = "image";
                });

              },
              child: Icon(
                Icons.image,
                size: 40,
                color: modeOpenAI == "image" ? Colors.white : Colors.grey,
              ),
            ),
          ),

        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              const SizedBox(height: 40,),
              //image
              Center(
                child: InkWell(
                  onTap: ()
                  {
                    speechToTextInstance.isListening
                        ? stopListeningNow ()
                        : startListeningNow();
                  },
                  child: speechToTextInstance.isListening
                      ? Center(child: LoadingAnimationWidget.beat(
                         size: 300,
                         color: speechToTextInstance.isListening
                             ? Colors.deepPurple
                             : isLoading
                             ? Colors.deepPurple[300]!
                             : Colors.deepPurple[150]!,
                        ),)
                      : Image.asset(
                    "images/assistant_icon.png",
                    height: 250,
                    width: 250,
                  ),
                ),
              ),

              const SizedBox(
                height: 50,
              ),


              //text field with a button

              Row(
                children: [

                  //text field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: TextField(
                        controller: userInputTextEditingController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "how can i help you?",
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10,),
                  //button
                  InkWell(
                    onTap: ()
                    {
                      if(userInputTextEditingController.text.isNotEmpty)
                        {
                          sendRequestToOpenAI(userInputTextEditingController.text.toString());
                        }
                    },
                    child: AnimatedContainer(
                      padding: const EdgeInsets.all(15),
                      decoration: const BoxDecoration(
                        shape: BoxShape.rectangle,
                        color: Colors.deepPurpleAccent
                      ),
                      duration: const Duration(
                        milliseconds: 1000,
                      ),
                      curve: Curves.bounceInOut,
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

            //display result 
            modeOpenAI == "chat" 
            ? SelectableText(
              answerTextFromOpenAI,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ) 
            : modeOpenAI == "image" && imageUrlFromOpenAI.isNotEmpty 
            ? Column(
              //image 
              children: [
                Image.network(
                  imageUrlFromOpenAI,
                ),
                const SizedBox(height: 14,),
                ElevatedButton(
                  onPressed: () async
                  {
                    String? imageStatus = await ImageDownloader.downloadImage(imageUrlFromOpenAI);

                    if(imageStatus != null)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Image Downloaded."),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  child: const Text(
                    "Download this Image",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ) 
            : Container()


            ],
          ),
        ),
      ),
    );
  }
}

