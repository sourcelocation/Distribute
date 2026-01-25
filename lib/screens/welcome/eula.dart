import 'package:flutter/material.dart';

class LegalSection {
  final String title;
  final String content;

  const LegalSection({required this.title, required this.content});
}

class EulaScreen extends StatelessWidget {
  const EulaScreen({
    super.key,
    required this.onAccepted,
    this.isOnboarding = false,
    this.onBack,
  });

  final VoidCallback onAccepted;
  final bool isOnboarding;
  final VoidCallback? onBack;

  static const String appName = "Distribute";

  static const String legalTitle = "Legal Disclaimer & Terms of Use";
  static const String legalSubtitle = "End-User License Agreement (EULA)";

  static final List<LegalSection> termsSections = [
    LegalSection(
      title: "1. Nature of the Service",
      content:
          '$appName ("the Software") is a neutral technology platform designed to facilitate the streaming and management of self-hosted media libraries. The Software functions exclusively as a client-interface tool. The developers of the Software ("the Developers") do not host, index, provide, or control any media content whatsoever.',
    ),
    LegalSection(
      title: "2. User Responsibility & Copyright Compliance",
      content:
          'The Software relies entirely on user-provided server addresses and credentials. By entering a server URL and accessing content, you warrant that:\n\n'
          '• You are the owner or authorized administrator of the server.\n'
          '• You hold the legal copyright or a valid license for all media files (audio, video, metadata, or images) stored on and streamed from said server.\n'
          '• Your use of the media complies with all applicable copyright laws in your jurisdiction.',
    ),
    LegalSection(
      title: "3. Prohibition of Copyright Infringement (Piracy)",
      content:
          'The Developers strictly condemn piracy and copyright infringement. The Software is intended solely for the playback of legally acquired content (e.g., rips of physically owned media, authorized digital purchases).\n\n'
          '• Prohibited Acts: You may not use the Software to access public trackers, illegal file dumps, or any repository containing content you do not own.\n'
          '• Zero Tolerance: We reserve the right to terminate support or access for any user known to be utilizing the Software for illegal distribution or consumption of copyrighted works, to the extent technically feasible.',
    ),
    LegalSection(
      title: "4. Indemnification",
      content:
          'You agree to indemnify, defend, and hold harmless the Developers, their contributors, and affiliates from any claims, damages, legal fees, or liabilities arising out of your use of the Software, specifically including but not limited to claims of copyright infringement, unauthorized distribution, or violation of intellectual property laws.',
    ),
    LegalSection(
      title: "5. No Warranty",
      content:
          'The Software is provided "as is," without warranty of any kind, express or implied. The Developers make no representation regarding the legality of specific use cases in your specific jurisdiction. It is your responsibility to verify that your self-hosting setup complies with local laws.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOnboarding) ...[
                  Text(
                    "Legal Stuff",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  legalTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  legalSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const Divider(height: 32, thickness: 1.5),

                ...termsSections.map((section) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          section.content,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // Footer actions
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: isOnboarding
                ? Colors.transparent
                : Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: isOnboarding
              ? Row(
                  children: [
                    if (onBack != null)
                      TextButton(onPressed: onBack, child: const Text("Back")),
                    const Spacer(),
                    FilledButton(
                      onPressed: onAccepted,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: const Text("I Agree"),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAccepted,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text("Close"),
                  ),
                ),
        ),
      ],
    );

    if (isOnboarding) {
      return content;
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Legal"),
          automaticallyImplyLeading: true,
          elevation: 0,
        ),
        body: content,
      ),
    );
  }
}
