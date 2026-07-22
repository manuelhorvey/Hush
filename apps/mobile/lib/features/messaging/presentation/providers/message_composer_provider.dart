import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the message composer (input field).
class MessageComposerState {
  final String text;
  final bool isEnabled;
  final bool isSending;

  const MessageComposerState({
    this.text = '',
    this.isEnabled = true,
    this.isSending = false,
  });

  MessageComposerState copyWith({
    String? text,
    bool? isEnabled,
    bool? isSending,
  }) {
    return MessageComposerState(
      text: text ?? this.text,
      isEnabled: isEnabled ?? this.isEnabled,
      isSending: isSending ?? this.isSending,
    );
  }

  bool get canSend => text.trim().isNotEmpty && isEnabled && !isSending;
}

/// Notifier for the message composer state.
///
/// Manages the input field state: text content, enabled/disabled,
/// and sending status. Clears the input on successful send.
class MessageComposerNotifier extends Notifier<MessageComposerState> {
  @override
  MessageComposerState build() {
    return const MessageComposerState();
  }

  void setText(String text) {
    state = state.copyWith(text: text);
  }

  void setEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
  }

  void setSending(bool sending) {
    state = state.copyWith(isSending: sending);
  }

  /// Clear the text after send.
  void onSent() {
    state = const MessageComposerState();
  }
}

/// Provider for the message composer state.
final messageComposerProvider =
    NotifierProvider<MessageComposerNotifier, MessageComposerState>(
  MessageComposerNotifier.new,
);
