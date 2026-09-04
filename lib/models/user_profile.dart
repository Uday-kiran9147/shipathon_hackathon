/// User Profile Model for Prevue Creator Intelligence
class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final List<String> connectedChannels;
  final String activeChannelHandle;
  final bool isGuest;
  final bool isPro;
  final String? authToken;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.connectedChannels = const ['@uk'],
    this.activeChannelHandle = '@uk',
    this.isGuest = false,
    this.isPro = false,
    this.authToken,
    required this.createdAt,
  });

  /// Factory for initial anonymous guest creator session
  factory UserProfile.guest([String initialHandle = '@uk']) {
    return UserProfile(
      id: 'guest_anonymous_creator',
      email: 'creator@studio.prevue.app',
      displayName: 'Guest Creator',
      photoUrl: null,
      connectedChannels: [initialHandle],
      activeChannelHandle: initialHandle,
      isGuest: true,
      isPro: false,
      authToken: null,
      createdAt: DateTime.now(),
    );
  }

  /// Preset Demo Accounts for Hackathon Judges & 1-Tap Testing
  static List<UserProfile> demoAccounts() {
    return [
      UserProfile(
        id: 'usr_demo_alex_rc',
        email: 'alex.rivera@creatorstudio.io',
        displayName: 'Alex Rivera (Pro Creator)',
        photoUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        connectedChannels: const ['@RevenueCat', '@mkbhd', '@Telusko'],
        activeChannelHandle: '@RevenueCat',
        isGuest: false,
        isPro: true,
        authToken: 'mock_jwt_demo_alex_rc',
        createdAt: DateTime(2025, 1, 15),
      ),
      UserProfile(
        id: 'usr_demo_fireship',
        email: 'jeff@fireship.io',
        displayName: 'Jeff Delaney (Fireship)',
        photoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        connectedChannels: const ['@Fireship', '@MrBeast'],
        activeChannelHandle: '@Fireship',
        isGuest: false,
        isPro: true,
        authToken: 'mock_jwt_demo_fireship',
        createdAt: DateTime(2025, 2, 1),
      ),
      UserProfile(
        id: 'usr_demo_tech_starter',
        email: 'naveen@teluskolearning.com',
        displayName: 'Naveen Reddy',
        photoUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        connectedChannels: const ['@Telusko'],
        activeChannelHandle: '@Telusko',
        isGuest: false,
        isPro: false,
        authToken: 'mock_jwt_demo_telusko',
        createdAt: DateTime(2025, 3, 10),
      ),
    ];
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    List<String>? connectedChannels,
    String? activeChannelHandle,
    bool? isGuest,
    bool? isPro,
    String? authToken,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      connectedChannels: connectedChannels ?? this.connectedChannels,
      activeChannelHandle: activeChannelHandle ?? this.activeChannelHandle,
      isGuest: isGuest ?? this.isGuest,
      isPro: isPro ?? this.isPro,
      authToken: authToken ?? this.authToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawChannels =
        json['connectedChannels'] ?? json['connected_channels'];
    final channels = (rawChannels is List)
        ? rawChannels.map((e) => e.toString()).toList()
        : const ['@RevenueCat'];

    final rawCreatedAt = json['createdAt'] ?? json['created_at'];

    return UserProfile(
      id: (json['id'] ?? json['sub']) as String? ?? 'guest_user',
      email: (json['email'] as String?)?.trim() ?? 'guest@prevue.app',
      displayName:
          (json['displayName'] ?? json['display_name']) as String? ?? 'Creator',
      photoUrl: (json['photoUrl'] ?? json['photo_url']) as String?,
      connectedChannels: channels.isNotEmpty ? channels : const ['@RevenueCat'],
      activeChannelHandle:
          (json['activeChannelHandle'] ?? json['active_channel_handle'])
              as String? ??
          (channels.isNotEmpty ? channels.first : '@RevenueCat'),
      isGuest: json['isGuest'] as bool? ?? json['is_guest'] as bool? ?? false,
      isPro: json['isPro'] as bool? ?? json['is_pro'] as bool? ?? false,
      authToken: (json['authToken'] ?? json['token']) as String?,
      createdAt: rawCreatedAt != null
          ? DateTime.tryParse(rawCreatedAt.toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'connectedChannels': connectedChannels,
    'activeChannelHandle': activeChannelHandle,
    'isGuest': isGuest,
    'isPro': isPro,
    'is_pro': isPro,
    'authToken': authToken,
    'createdAt': createdAt.toIso8601String(),
  };
}
