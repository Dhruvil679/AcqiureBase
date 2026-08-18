// Cloudinary credentials for unsigned uploads.
//
// Create an unsigned upload preset in your Cloudinary console:
// Settings → Upload → Upload presets → Add upload preset → Signing: Unsigned.
// Then paste your cloud name and preset below.
class CloudinaryConfig {
  const CloudinaryConfig._();

  static const String cloudName = 'pkplgkql';
  static const String uploadPreset = 'acquirebase_unsigned';

  // Folders keep uploaded assets organized in Cloudinary.
  static const String avatarsFolder = 'acquirebase/avatars';
  static const String logosFolder = 'acquirebase/logos';
  static const String screenshotsFolder = 'acquirebase/screenshots';
  static const String documentsFolder = 'acquirebase/documents';
}
