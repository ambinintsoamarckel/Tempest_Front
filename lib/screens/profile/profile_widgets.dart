import 'package:flutter/material.dart';
import 'package:mini_social_network/models/profile.dart';
import 'package:mini_social_network/theme/app_theme.dart';

// Widget pour l'avatar avec bordure de story
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final bool hasStories;
  final VoidCallback? onTap;
  final VoidCallback? onCameraPressed;

  const ProfileAvatar({
    Key? key,
    this.photoUrl,
    this.hasStories = false,
    this.onTap,
    this.onCameraPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasStories ? onTap : null,
      child: Hero(
        tag: 'profile_avatar',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasStories
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.secondaryColor,
                      AppTheme.accentColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: hasStories ? const EdgeInsets.all(4) : EdgeInsets.zero,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 4,
                  ),
                ),
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 60,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
              ),
              if (onCameraPressed != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onCameraPressed,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les champs éditables
class EditableProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onSave;
  final bool enabled;

  const EditableProfileField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.isEditing,
    required this.onEdit,
    required this.onSave,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEditing
              ? AppTheme.primaryColor
              : Theme.of(context).dividerColor.withOpacity(0.2),
          width: isEditing ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEditing && enabled,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: label,
                  border: InputBorder.none,
                  labelStyle: TextStyle(
                    color: isEditing ? AppTheme.primaryColor : null,
                  ),
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: enabled ? (isEditing ? onSave : onEdit) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    isEditing ? Icons.check_rounded : Icons.edit_rounded,
                    color: enabled ? AppTheme.primaryColor : Colors.grey,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour les options du menu
class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final bool isDangerous;

  const ProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.isDangerous = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color =
        isDangerous ? Colors.red : (iconColor ?? AppTheme.primaryColor);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDangerous ? Colors.red : null,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget pour les champs de mot de passe
class PasswordFields extends StatefulWidget {
  final TextEditingController oldPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;
  final bool isLoading;

  const PasswordFields({
    Key? key,
    required this.oldPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PasswordFields> createState() => _PasswordFieldsState();
}

class _PasswordFieldsState extends State<PasswordFields> {
  bool _showOldPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPasswordField(
              controller: widget.oldPasswordController,
              label: 'Ancien mot de passe',
              isVisible: _showOldPassword,
              onToggle: () =>
                  setState(() => _showOldPassword = !_showOldPassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: widget.newPasswordController,
              label: 'Nouveau mot de passe',
              isVisible: _showNewPassword,
              onToggle: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: widget.confirmPasswordController,
              label: 'Confirmer le mot de passe',
              isVisible: _showConfirmPassword,
              onToggle: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onSubmit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Changer le mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: AppTheme.primaryColor,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}

// Widget pour la liste des groupes
class GroupsList extends StatelessWidget {
  final List<Group> groups;

  const GroupsList({
    Key? key,
    required this.groups,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.group_outlined,
                size: 48,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun groupe',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Text(
            'Mes Groupes (${groups.length})',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).dividerColor.withOpacity(0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage:
                      group.photo != null ? NetworkImage(group.photo!) : null,
                  child: group.photo == null
                      ? Icon(
                          Icons.group_rounded,
                          color: AppTheme.primaryColor,
                        )
                      : null,
                ),
                title: Text(
                  group.nom,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: group.description != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          group.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : null,
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
