/// NX ID formatting utilities for signaling message routing.
library;

/// Utility class for formatting NX IDs.
class NxIdUtils {
  static const defaultDomain = 'nxservice.quantumvision-tech.com';

  /// Format a phone number or partial NX ID into a bare NX ID (no resource).
  static String format(String nxid, {String domain = defaultDomain}) {
    var clean = nxid.trim();
    if (clean.isEmpty) return clean;

    if (!clean.contains('@')) {
      var phone = clean.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      if (!phone.startsWith('+') && phone.isNotEmpty) {
        phone = '+$phone';
      }
      clean = '$phone@$domain';
    }

    if (clean.contains('@')) {
      final parts = clean.split('@');
      if (parts.length >= 2) {
        var username = parts[0].replaceAll(RegExp(r'[\s\-\(\)]'), '');
        if (!username.startsWith('+') && username.isNotEmpty) {
          username = '+$username';
        }
        final domainPart = parts[1].split('/')[0];
        clean = '$username@$domainPart';
      }
    }

    return clean;
  }

  /// Strip resource suffix and normalize (e.g. user@domain/nexacon_123 → user@domain).
  static String bare(String nxid, {String domain = defaultDomain}) {
    return format(nxid, domain: domain);
  }

  /// Resolve a phone or NX ID to a full NX ID using the authenticated user's
  /// NX ID as a hint for the domain.
  static String resolve(String to, {String? myNxId}) {
    if (to.contains('@')) return bare(to);

    final domain = (myNxId != null && myNxId.contains('@'))
        ? myNxId.split('@')[1].split('/')[0]
        : defaultDomain;

    return format(to, domain: domain);
  }
}
