import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:nexentis_ai/bloc/cubit/search_cubit.dart';
import 'package:nexentis_ai/bloc/cubit/search_state.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<_ChatMessage> messages = [];

  @override
  void dispose() {
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final query = searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      messages.add(_ChatMessage(text: query, isUser: true));
    });

    context.read<SearchCubit>().getSearchResponse(query: query);
    searchController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome, color: colorScheme.primary),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NexentisAi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text('Pro', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SearchCubit, SearchState>(
          listener: (_, state) {
            if (state is SearchLoadedState) {
              setState(() {
                messages.add(_ChatMessage(text: state.res, isUser: false));
              });
              _scrollToBottom();
            }
            if (state is SearchErrorState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error)));
            }
          },
          builder: (_, state) {
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'What’s on your mind today?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _MessageBubble(message: message);
                          },
                        ),
                ),
                if (state is SearchLoadingState)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 8,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: colorScheme.primaryContainer,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedTextKit(
                              repeatForever: true,
                              animatedTexts: [
                                TypewriterAnimatedText(
                                  'Thinking...',
                                  speed: const Duration(milliseconds: 70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          minLines: 1,
                          maxLines: 5,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Ask Anything with NexentisAI',
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: state is SearchLoadingState
                            ? null
                            : _sendMessage,
                        icon: const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bubbleColor = message.isUser
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final align = message.isUser
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final margin = message.isUser
        ? const EdgeInsets.only(left: 56, bottom: 10)
        : const EdgeInsets.only(right: 56, bottom: 10);

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: message.isUser
              ? Text(message.text,)
              // : GptMarkdown(message.text, style: const TextStyle(fontSize: 14)),
              : AnimatedTextKit(
                     animatedTexts: [
                    TypewriterAnimatedText(message.text, textAlign: TextAlign.left, 
                    speed: Duration(milliseconds: 10)),
                  ],
              ),
       ),
      ],
    );
  }
}
