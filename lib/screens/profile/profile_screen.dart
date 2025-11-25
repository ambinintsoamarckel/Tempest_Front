import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/theme_provider.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'profile_logic.dart';
import 'profile_widgets.dart';
import '../archive_screen.dart' as archive;
import '../all_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late ProfileLogic _logic;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logic = ProfileLogic();
    _logic.addListener(() {
      if (mounted) setState(() {});
    });
    _logic.loadUser();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _logic.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Dialogue de confirmation
  Future<bool> _showConfirmationDialog(String title, String message,
      {bool isDangerous = false}) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    isDangerous ? Icons.warning_rounded : Icons.info_rounded,
                    color: isDangerous ? Colors.red : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isDangerous ? Colors.red : null,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDangerous ? Colors.red : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Confirmer'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Sélection de photo
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Galerie'),
                onTap: () async {
                  Navigator.pop(context);
                  bool confirm = await _showConfirmationDialog(
                    'Changer la photo',
                    'Voulez-vous changer votre photo de profil ?',
                  );
                  if (confirm) {
                    await _logic.updateProfilePhoto(ImageSource.gallery);
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                title: const Text('Caméra'),
                onTap: () async {
                  Navigator.pop(context);
                  bool confirm = await _showConfirmationDialog(
                    'Changer la photo',
                    'Voulez-vous changer votre photo de profil ?',
                  );
                  if (confirm) {
                    await _logic.updateProfilePhoto(ImageSource.camera);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Déconnexion
  void _handleLogout() async {
    bool confirm = await _showConfirmationDialog(
      'Déconnexion',
      'Voulez-vous vraiment vous déconnecter ?',
    );
    if (confirm) {
      bool success = await _logic.logout();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  // Suppression du compte
  void _handleDeleteAccount() async {
    bool confirm = await _showConfirmationDialog(
      'Supprimer le compte',
      'Cette action est irréversible. Voulez-vous vraiment supprimer votre compte ?',
      isDangerous: true,
    );
    if (confirm) {
      bool success = await _logic.deleteAccount();
      if (success && mounted) {
        Navigator.pushReplacementNamed(context, '/');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression du compte'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Changement de mot de passe
  void _handlePasswordChange() async {
    String? error = await _logic.changePassword();
    if (mounted) {
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié avec succès'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Navigation vers les archives
  void _navigateToArchives() {
    if (_logic.user?.archives != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              archive.StoryScreen(stories: _logic.user!.archives),
        ),
      );
    }
  }

  // Navigation vers les stories
  void _navigateToStories() {
    if (_logic.user?.stories != null && _logic.user!.stories.isNotEmpty) {
      final storyIds = _logic.user!.stories.map((story) => story.id).toList();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllStoriesScreen(
            initialIndex: 0,
            storyIds: storyIds,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final user = _logic.user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient de fond
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Contenu principal
          if (_logic.isLoading && user == null)
            const Center(child: CircularProgressIndicator())
          else if (user != null)
            FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    // Avatar
                    ProfileAvatar(
                      photoUrl: user.photo,
                      hasStories: user.stories.isNotEmpty,
                      onTap: _navigateToStories,
                      onCameraPressed: _showImageSourceDialog,
                    ),

                    const SizedBox(height: 32),

                    // Contenu du profil
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section Informations
                          _buildSection(
                            title: 'Informations personnelles',
                            icon: Icons.person_rounded,
                            children: [
                              EditableProfileField(
                                controller: _logic.nameController,
                                label: 'Nom complet',
                                icon: Icons.badge_rounded,
                                isEditing: _logic.isEditingName,
                                enabled: !_logic.isLoading,
                                onEdit: _logic.toggleNameEditing,
                                onSave: () async {
                                  await _logic.updateName(
                                      _logic.nameController.text.trim());
                                },
                              ),
                              const SizedBox(height: 12),
                              EditableProfileField(
                                controller: _logic.emailController,
                                label: 'Adresse email',
                                icon: Icons.email_rounded,
                                isEditing: _logic.isEditingEmail,
                                enabled: !_logic.isLoading,
                                onEdit: _logic.toggleEmailEditing,
                                onSave: () async {
                                  await _logic.updateEmail(
                                      _logic.emailController.text.trim());
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Thème
                          _buildSection(
                            title: 'Apparence',
                            icon: Icons.palette_rounded,
                            children: [
                              _buildThemeToggle(themeProvider),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Sécurité
                          _buildSection(
                            title: 'Sécurité',
                            icon: Icons.security_rounded,
                            children: [
                              ProfileMenuItem(
                                icon: Icons.lock_rounded,
                                title: 'Modifier le mot de passe',
                                subtitle: 'Changez votre mot de passe',
                                trailing: Transform.rotate(
                                  angle:
                                      _logic.showPasswordFields ? 3.14159 : 0,
                                  child: const Icon(Icons.expand_more_rounded),
                                ),
                                onTap: _logic.togglePasswordFields,
                              ),
                              if (_logic.showPasswordFields) ...[
                                const SizedBox(height: 12),
                                PasswordFields(
                                  oldPasswordController:
                                      _logic.oldPasswordController,
                                  newPasswordController:
                                      _logic.newPasswordController,
                                  confirmPasswordController:
                                      _logic.confirmPasswordController,
                                  onSubmit: _handlePasswordChange,
                                  isLoading: _logic.isLoading,
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Contenu
                          _buildSection(
                            title: 'Mon contenu',
                            icon: Icons.collections_rounded,
                            children: [
                              ProfileMenuItem(
                                icon: Icons.archive_rounded,
                                title: 'Archives et Stories',
                                subtitle: 'Consultez vos archives',
                                onTap: _navigateToArchives,
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Section Groupes
                          if (user.groupes.isNotEmpty) ...[
                            _buildSection(
                              title: 'Mes groupes',
                              icon: Icons.group_rounded,
                              children: [
                                GroupsList(groups: user.groupes),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Section Actions dangereuses
                          _buildSection(
                            title: 'Zone de danger',
                            icon: Icons.warning_rounded,
                            isDanger: true,
                            children: [
                              ProfileMenuItem(
                                icon: Icons.logout_rounded,
                                title: 'Déconnexion',
                                subtitle: 'Se déconnecter de l\'application',
                                onTap: _handleLogout,
                              ),
                              const SizedBox(height: 12),
                              ProfileMenuItem(
                                icon: Icons.delete_forever_rounded,
                                title: 'Supprimer mon compte',
                                subtitle: 'Action irréversible',
                                onTap: _handleDeleteAccount,
                                isDangerous: true,
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Indicateur de chargement overlay
          if (_logic.isLoading && user != null)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mise à jour en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool isDanger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isDanger ? Colors.red : AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDanger ? Colors.red : null,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildThemeToggle(ThemeProvider themeProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.all(16),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            color: AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: const Text(
          'Mode sombre',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          themeProvider.isDarkMode ? 'Activé' : 'Désactivé',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
        activeColor: AppTheme.primaryColor,
      ),
    );
  }
}
