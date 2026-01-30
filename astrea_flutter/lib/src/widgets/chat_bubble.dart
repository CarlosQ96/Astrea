import 'package:flutter/material.dart';

import '../providers/chat_provider.dart';
import '../theme/astrea_colors.dart';
import 'particle_dissolve.dart';

/// Displays a single chat message bubble with ephemeral dissolution effect.
/// Optimized for 60fps with const decorations.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onDissolveComplete;

  // Const decorations for performance
  static const _userBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(4),
  );
  static const _aiBorderRadius = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );
  static const _actionBadgeRadius = BorderRadius.all(Radius.circular(8));
  static const _aiBorder = Border.fromBorderSide(
    BorderSide(color: AstreaColors.mysticViolet, width: 1),
  );

  const ChatBubble({
    super.key,
    required this.message,
    this.onDissolveComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return ParticleDissolve(
      dissolve: message.isDissolving,
      onDissolveComplete: onDissolveComplete,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AstreaColors.starlightCyan
                      : AstreaColors.astralPurple,
                  borderRadius: isUser ? _userBorderRadius : _aiBorderRadius,
                  border: isUser ? null : _aiBorder,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: TextStyle(
                        color: isUser
                            ? AstreaColors.deepVoid
                            : AstreaColors.starWhite,
                      ),
                    ),
                    if (!isUser && message.actionParsed) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AstreaColors.success.withValues(alpha: 0.2),
                          borderRadius: _actionBadgeRadius,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AstreaColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Action completed',
                              style: TextStyle(
                                color: AstreaColors.success,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isUser) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
