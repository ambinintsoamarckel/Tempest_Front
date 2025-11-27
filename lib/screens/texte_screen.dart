import 'package:flutter/material.dart';
import 'package:mini_social_network/services/story_service.dart';
import '../theme/app_theme.dart';

class TextStoryScreen extends StatefulWidget {
  final VoidCallback onStoryCreated;

  const TextStoryScreen({super.key, required this.onStoryCreated});

  @override
  _TextStoryScreenState createState() => _TextStoryScreenState();
}

class _TextStoryScreenState extends State<TextStoryScreen>
    with SingleTickerProviderStateMixin {
  Color _backgroundColor = const Color(0xFFFF6B6B);
  String _storyText = "";
  Color _textColor = Colors.white;
  TextAlign _textAlign = TextAlign.center;
  FontWeight _fontWeight = FontWeight.w600;
  double _fontSize = 28.0;

  final TextEditingController _textController = TextEditingController();
  final StoryService _storyService = StoryService();
  bool _isCreating = false;
  bool _showColorPicker = false;
  bool _isTextColorPicker = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Palettes de couleurs prédéfinies
  final List<Color> _backgroundColors = [
    const Color(0xFFFF6B6B), // Rouge corail
    const Color(0xFF4ECDC4), // Turquoise
    const Color(0xFF45B7D1), // Bleu ciel
    const Color(0xFF96CEB4), // Vert menthe
    const Color(0xFFFECE63), // Jaune doré
    const Color(0xFFFF8B94), // Rose
    const Color(0xFF9B59B6), // Violet
    const Color(0xFF3498DB), // Bleu
    const Color(0xFFE67E22), // Orange
    const Color(0xFF1ABC9C), // Turquoise foncé
    const Color(0xFFE74C3C), // Rouge
    const Color(0xFF34495E), // Gris bleuté
  ];

  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    const Color(0xFFFFD700), // Or
    const Color(0xFFFF1493), // Rose vif
    const Color(0xFF00CED1), // Cyan
    const Color(0xFFFF6347), // Tomate
    const Color(0xFF9370DB), // Violet moyen
    const Color(0xFF00FA9A), // Vert spring
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submitStory() async {
    if (_storyText.trim().isEmpty) {
      _showErrorSnackBar('Veuillez écrire du texte');
      return;
    }

    if (!mounted) return;

    setState(() {
      _isCreating = true;
    });

    // Convertir les couleurs en format hex
    String bgColorHex =
        '#${_backgroundColor.value.toRadixString(16).substring(2)}';
    String textColorHex = '#${_textColor.value.toRadixString(16).substring(2)}';

    Map<String, dynamic> storyData = {
      'type': 'texte',
      'texte': _storyText,
      'backgroundColor': bgColorHex,
      'textColor': textColorHex,
      'textAlign':
          _textAlign.toString().split('.').last, // 'left', 'center', 'right'
      'fontSize': _fontSize,
      'fontWeight':
          _fontWeight.toString().split('.').last, // 'w600', 'w700', etc.
    };

    try {
      await _storyService.createStory(storyData);

      if (!mounted) return;

      widget.onStoryCreated();
      _showSuccessSnackBar('Story créée avec succès !');

      // Retourner true pour indiquer le succès
      Navigator.of(context).pop(true);
    } catch (e) {
      print('❌ Failed to create story: $e');

      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });
      _showErrorSnackBar('Erreur lors de la création');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _toggleColorPicker(bool isTextColor) {
    setState(() {
      _showColorPicker = !_showColorPicker;
      _isTextColorPicker = isTextColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // 🎨 Effet de dégradé subtil pour plus de profondeur
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _backgroundColor,
                  _backgroundColor.withOpacity(0.85),
                ],
              ),
            ),
          ),

          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // AppBar personnalisée
                _buildAppBar(),

                // Zone de texte - SANS fond blanc
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showColorPicker = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Center(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: TextField(
                            controller: _textController,
                            style: TextStyle(
                              color: _textColor,
                              fontSize: _fontSize,
                              fontWeight: _fontWeight,
                              height: 1.4,
                              shadows: [
                                // ✨ Ombre portée pour améliorer la lisibilité
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: const Offset(0, 2),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            decoration: InputDecoration(
                              hintText: 'Écrivez votre message...',
                              hintStyle: TextStyle(
                                color: _textColor.withOpacity(0.4),
                                fontSize: _fontSize,
                                fontWeight: _fontWeight,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              filled: false,
                              fillColor: Colors.transparent,
                            ),
                            textAlign: _textAlign,
                            maxLines: null,
                            maxLength: 200,
                            cursorColor: _textColor,
                            onChanged: (value) {
                              setState(() {
                                _storyText = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Barre d'outils en bas
                _buildToolbar(),
              ],
            ),
          ),

          // Color picker overlay
          if (_showColorPicker) _buildColorPickerOverlay(),

          // Loading overlay
          if (_isCreating) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Bouton retour avec effet glassmorphism
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const Spacer(),
          // Bouton partager avec design moderne
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCreating ? null : _submitStory,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: _backgroundColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Partager',
                        style: TextStyle(
                          color: _backgroundColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildToolbar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            icon: Icons.palette_rounded,
            label: 'Fond',
            onTap: () => _toggleColorPicker(false),
          ),
          _buildToolButton(
            icon: Icons.format_color_text_rounded,
            label: 'Texte',
            onTap: () => _toggleColorPicker(true),
          ),
          _buildToolButton(
            icon: _textAlign == TextAlign.left
                ? Icons.format_align_left_rounded
                : _textAlign == TextAlign.center
                    ? Icons.format_align_center_rounded
                    : Icons.format_align_right_rounded,
            label: 'Aligner',
            onTap: _cycleTextAlign,
          ),
          _buildToolButton(
            icon: Icons.format_size_rounded,
            label: 'Taille',
            onTap: _cycleFontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPickerOverlay() {
    final colors = _isTextColorPicker ? _textColors : _backgroundColors;

    return Positioned(
      bottom: 110,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              _isTextColorPicker ? 'Couleur du texte' : 'Couleur de fond',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: colors.map((color) {
                final isSelected = _isTextColorPicker
                    ? color == _textColor
                    : color == _backgroundColor;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_isTextColorPicker) {
                        _textColor = color;
                      } else {
                        _backgroundColor = color;
                      }
                      _showColorPicker = false;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Publication...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleTextAlign() {
    setState(() {
      if (_textAlign == TextAlign.left) {
        _textAlign = TextAlign.center;
      } else if (_textAlign == TextAlign.center) {
        _textAlign = TextAlign.right;
      } else {
        _textAlign = TextAlign.left;
      }
    });
  }

  void _cycleFontSize() {
    setState(() {
      if (_fontSize == 24.0) {
        _fontSize = 28.0;
      } else if (_fontSize == 28.0) {
        _fontSize = 32.0;
      } else if (_fontSize == 32.0) {
        _fontSize = 36.0;
      } else {
        _fontSize = 24.0;
      }
    });
  }
}
