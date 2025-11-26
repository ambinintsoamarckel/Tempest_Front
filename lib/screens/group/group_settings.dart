import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_social_network/screens/membre_screen.dart';
import '../../../models/group_message.dart';
import 'package:mini_social_network/theme/app_theme.dart';
import 'group_logic.dart';

class GroupSettingsScreen extends StatefulWidget {
  final Group groupe;

  const GroupSettingsScreen({super.key, required this.groupe});

  @override
  _GroupSettingsScreenState createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen>
    with SingleTickerProviderStateMixin {
  late GroupLogic _logic;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _logic = GroupLogic(widget.groupe);
    _logic.addListener(() {
      if (mounted) setState(() {});
    });

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
  Future<bool> _showConfirmationDialog(
    String title,
    String message, {
    bool isDangerous = false,
  }) async {
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
                  'Photo du groupe',
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
                onTap: () => _handleImagePick(ImageSource.gallery),
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
                onTap: () => _handleImagePick(ImageSource.camera),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _handleImagePick(ImageSource source) async {
    Navigator.pop(context);
    bool confirm = await _showConfirmationDialog(
      'Changer la photo',
      'Voulez-vous changer la photo du groupe ?',
    );
    if (confirm) {
      bool success = await _logic.pickAndUpdatePhoto(source);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Photo du groupe mise à jour'
                  : 'Erreur lors de la mise à jour',
            ),
            backgroundColor: success ? AppTheme.secondaryColor : Colors.red,
          ),
        );
      }
    }
  }

  void _handleUpdateName() async {
    bool success = await _logic.updateGroupName();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Nom du groupe mis à jour'
                : 'Erreur lors de la mise à jour',
          ),
          backgroundColor: success ? AppTheme.secondaryColor : Colors.red,
        ),
      );
    }
  }

  void _handleUpdateDescription() async {
    bool success = await _logic.updateGroupDescription();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Description mise à jour'
                : 'Erreur lors de la mise à jour',
          ),
          backgroundColor: success ? AppTheme.secondaryColor : Colors.red,
        ),
      );
    }
  }

  void _handleAddMember() async {
    final addedContacts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContaScreen(groupId: _logic.group!.id),
      ),
    );
    if (addedContacts != null) {
      await _logic.addMember(addedContacts);
    }
  }

  void _handleRemoveMember(String memberId) async {
    bool confirm = await _showConfirmationDialog(
      'Retirer le membre',
      'Êtes-vous sûr de vouloir retirer ce membre du groupe ?',
      isDangerous: true,
    );

    if (confirm) {
      bool success = await _logic.removeMember(memberId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Membre retiré du groupe'
                  : 'Erreur lors de la suppression',
            ),
            backgroundColor: success ? AppTheme.secondaryColor : Colors.red,
          ),
        );
      }
    }
  }

  void _handleLeaveGroup() async {
    bool confirm = await _showConfirmationDialog(
      'Quitter le groupe',
      'Êtes-vous sûr de vouloir quitter ce groupe ?',
    );

    if (confirm) {
      bool success = await _logic.leaveGroup();
      if (success && mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sortie du groupe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleDeleteGroup() async {
    bool confirm = await _showConfirmationDialog(
      'Supprimer le groupe',
      'Cette action est irréversible. Voulez-vous vraiment supprimer ce groupe ?',
      isDangerous: true,
    );

    if (confirm) {
      bool success = await _logic.deleteGroup();
      if (success && mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la suppression du groupe'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _logic.group;
    if (group == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Paramètres du groupe',
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
          FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 100),
              child: Column(
                children: [
                  // Avatar du groupe
                  _buildGroupAvatar(),

                  const SizedBox(height: 32),

                  // Contenu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section Informations
                        _buildSection(
                          title: 'Informations du groupe',
                          icon: Icons.info_rounded,
                          children: [
                            _buildEditableField(
                              controller: _logic.nameController,
                              label: 'Nom du groupe',
                              icon: Icons.group_rounded,
                              isEditing: _logic.isEditingName,
                              onEdit: _logic.toggleNameEditing,
                              onSave: _handleUpdateName,
                            ),
                            const SizedBox(height: 12),
                            _buildEditableField(
                              controller: _logic.descriptionController,
                              label: 'Description',
                              icon: Icons.description_rounded,
                              isEditing: _logic.isEditingDescription,
                              onEdit: _logic.toggleDescriptionEditing,
                              onSave: _handleUpdateDescription,
                            ),
                            const SizedBox(height: 12),
                            _buildCreatorInfo(),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section Membres
                        _buildSection(
                          title: 'Membres (${group.membres.length})',
                          icon: Icons.people_rounded,
                          children: [
                            if (_logic.isCreator) ...[
                              _buildMenuItem(
                                icon: Icons.person_add_rounded,
                                title: 'Ajouter un membre',
                                subtitle: 'Inviter de nouveaux membres',
                                onTap: _handleAddMember,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _buildMembersList(),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Section Actions dangereuses
                        _buildSection(
                          title: 'Zone de danger',
                          icon: Icons.warning_rounded,
                          isDanger: true,
                          children: [
                            if (_logic.isCreator)
                              _buildMenuItem(
                                icon: Icons.delete_forever_rounded,
                                title: 'Supprimer le groupe',
                                subtitle: 'Action irréversible',
                                onTap: _handleDeleteGroup,
                                isDangerous: true,
                              )
                            else
                              _buildMenuItem(
                                icon: Icons.exit_to_app_rounded,
                                title: 'Quitter le groupe',
                                subtitle: 'Vous ne recevrez plus les messages',
                                onTap: _handleLeaveGroup,
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
          if (_logic.isLoading)
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

  Widget _buildGroupAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage: _logic.group?.photo != null
                ? NetworkImage(_logic.group!.photo!)
                : null,
            child: _logic.group?.photo == null
                ? const Icon(Icons.groups_rounded, size: 50)
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 3,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              onPressed: _showImageSourceDialog,
            ),
          ),
        ),
      ],
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

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isEditing,
    required VoidCallback onEdit,
    required VoidCallback onSave,
  }) {
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    enabled: isEditing,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check_rounded : Icons.edit_rounded,
                color:
                    isEditing ? AppTheme.secondaryColor : AppTheme.primaryColor,
              ),
              onPressed: isEditing ? onSave : onEdit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorInfo() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.secondaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.secondaryColor,
            size: 24,
          ),
        ),
        title: const Text(
          'Créateur',
          style: TextStyle(fontSize: 12),
        ),
        subtitle: Text(
          _logic.group!.createur.nom,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDangerous = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDangerous
              ? Colors.red.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDangerous
                ? Colors.red.withOpacity(0.1)
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDangerous ? Colors.red : AppTheme.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDangerous ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: isDangerous ? Colors.red : null,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _logic.getMembersExceptCurrent();

    if (members.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Aucun autre membre',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: members.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 72,
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
        itemBuilder: (context, index) {
          final member = members[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundImage:
                  member.photo != null ? NetworkImage(member.photo!) : null,
              child: member.photo == null
                  ? const Icon(Icons.person_rounded)
                  : null,
            ),
            title: Text(
              member.nom,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              member.email,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: _logic.isCreator
                ? IconButton(
                    icon: const Icon(
                      Icons.remove_circle_rounded,
                      color: Colors.red,
                    ),
                    onPressed: () => _handleRemoveMember(member.id),
                  )
                : null,
          );
        },
      ),
    );
  }
}

