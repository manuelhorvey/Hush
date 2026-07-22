/// Represents the delivery status of a message.
///
/// Follows Hush's privacy philosophy:
/// - No read receipts
/// - No seen status
/// - No typing indicators
enum MessageStatus {
  /// Message is being sent (optimistic UI state)
  sending,

  /// Message has been sent to the server
  sent,

  /// Message has been delivered to the recipient's device
  delivered,

  /// Message failed to send
  failed,

  /// Message is queued for retry (offline)
  pending;

  String get label {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.failed:
        return 'Failed';
      case MessageStatus.pending:
        return 'Pending';
    }
  }

  bool get isFinal => this == MessageStatus.sent || this == MessageStatus.failed;
  bool get isError => this == MessageStatus.failed;
}
