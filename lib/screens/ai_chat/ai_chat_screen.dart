import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../services/ai_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialMessage;

  const AiChatScreen({super.key, this.initialMessage});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    messages.add({
      "role": "ai",
      "text": "Hello 👋\nI am your MedAI assistant.\nHow can I help you today?",
    });

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty) {
      _sendMessage(widget.initialMessage!);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _streamAiMessage(String fullText) async {
    if (messages.isNotEmpty && messages.last["text"] == "typing...") {
      setState(() {
        messages.removeLast();
        messages.add({"role": "ai", "text": ""});
      });
    } else {
      setState(() {
        messages.add({"role": "ai", "text": ""});
      });
    }

    for (int i = 0; i < fullText.length; i++) {
      await Future.delayed(const Duration(milliseconds: 12));

      if (!mounted) return;

      setState(() {
        messages[messages.length - 1]["text"] =
            (messages[messages.length - 1]["text"] ?? "") + fullText[i];
      });

      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      messages.add({"role": "ai", "text": "typing..."});
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    String response = await AIService.analyzeMedicine(text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    await _streamAiMessage(response);
  }

  Widget _messageBubble(Map<String, String> msg) {
    final isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primaryPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: msg["text"] == "typing..."
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text("Typing..."),
                ],
              )
            : Text(
                msg["text"] ?? "",
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  height: 1.45,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.lightPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.smart_toy_rounded, color: Colors.white, size: 38),
                SizedBox(height: 14),
                Text(
                  "AI Medical Assistant",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Ask anything about medicines or health",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _messageBubble(messages[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 12),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: "Ask about medicine or health...",
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: IconButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    _sendMessage(_controller.text);
                                  },
                            icon: Icon(
                              Icons.send_rounded,
                              color: _isLoading
                                  ? Colors.grey
                                  : Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    AppConstants.medicalDisclaimer,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
