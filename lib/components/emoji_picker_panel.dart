import 'package:flutter/material.dart';

class CustomEmojiPanel extends StatefulWidget {
  final Function(String) onEmojiSelected;

  const CustomEmojiPanel({
    super.key,
    required this.onEmojiSelected,
  });

  @override
  State<CustomEmojiPanel> createState() => _CustomEmojiPanelState();
}

class _CustomEmojiPanelState extends State<CustomEmojiPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Emoji categories with their respective emojis and icons
  static final Map<IconData, Map<String, List<String>>> emojiCategories = {
    Icons.history: {
      '': [
        // Smileys & Emotions
        '😊', '😂', '😍', '😎', '😭', '😡', '😱', '🤔', '😴', '😇',

        // Hand Gestures
        '👍', '👏', '🙏', '🙌', '🤙', '👌', '🤝', '👊', '✌️', '🤞',

        // Hearts & Symbols
        '❤️', '💔', '💖', '💙', '💜', '🖤', '💯', '✔️', '❌', '⚡',

        // Animals & Nature
        '🐶', '🐱', '🦁', '🐼', '🐸', '🌸', '🌞', '🌈', '🔥', '🌍'
      ],
    },
    Icons.sentiment_satisfied: {
      'Faces': [
        '😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '🙃', '😉', '😌', '😍', '🥰',
        '😘', '😗', '😙', '😚', '😋', '😛', '😝', '😜', '🤪', '🤨', '🧐', '🤓', '😎', '🤩', '🥳',
      ],
      'Emotions': [
        '😏', '😒', '😞', '😔', '😟', '😕', '🙁', '☹️', '😣', '😖', '😫', '😩', '🥺', '😢', '😭',
        '😤', '😠', '😡', '🤬', '🤯', '😳', '🥵', '🥶', '😱', '😨', '😰', '😥', '😓', '🤗', '🤔',
      ],
    },
    Icons.pets: {
      'Animals': [
        '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮', '🐷', '🐸', '🐵',
        '🐔', '🐧', '🐦', '🐤', '🦆', '🦅', '🦉', '🦇', '🐺', '🐗', '🐴', '🦄', '🐝', '🐛', '🦋',
      ],
      'Nature': [
        '🌸', '💐', '🌷', '🌹', '🥀', '🌺', '🌸', '🌼', '🌻', '🌞', '🌝', '🌛', '🌜', '🌚', '🌕',
        '🌖', '🌗', '🌘', '🌑', '🌒', '🌓', '🌔', '🌙', '🌎', '🌍', '🌏', '🪐', '💫', '⭐️', '🌟',
      ],
    },
    Icons.fastfood: {
      'Food': [
        '🍎', '🍐', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍑', '🥭', '🍍', '🥥', '🥝',
        '🍅', '🍆', '🥑', '🥦', '🥬', '🥒', '🌶', '🌽', '🥕', '🥔', '🍠', '🥐', '🥯', '🍞', '🥖',
      ],
      'Drinks': [
        '☕️', '🫖', '🍵', '🧃', '🥤', '🧋', '🍶', '🍺', '🍻', '🥂', '🍷', '🥃', '🍸', '🍹', '🧉',
      ],
    },
    Icons.sports_baseball: {
      'Sports': [
        '⚽️', '🏀', '🏈', '⚾️', '🥎', '🎾', '🏐', '🏉', '🥏', '🎱', '🪀', '🏓', '🏸', '🏒', '🏑',
        '🥍', '🏏', '⛳️', '🪁', '🏹', '🎣', '🤿', '🥊', '🥋', '🎽', '🛹', '🛼', '🛷', '⛸', '🥌',
      ],
      'Activities': [
        '🎪', '🎭', '🎨', '🎬', '🎤', '🎧', '🎼', '🎹', '🥁', '🎷', '🎺', '🎸', '🪕', '🎻', '🎲',
        '♟', '🎯', '🎳', '🎮', '🎰', '🧩', '🚗', '✈️', '🚀', '🛸', '🎢', '🎡', '🎠', '🏰', '🗽',
      ],
    },
    Icons.computer: {
      'General': [
        '⌚️', '📱', '💻', '⌨️', '🖥', '🖨', '🖱', '🖲', '🕹', '🗜', '💽', '💾', '💿', '📀', '📼',
        '📷', '📸', '📹', '🎥', '📽', '🎞', '📞', '☎️', '📟', '📠', '📺', '📻', '🎙', '🎚', '🎛',
      ],
      'Tools': [
        '🔧', '🔨', '⚒', '🛠', '⛏', '🔩', '⚙️', '🗜', '⚖️', '🔗', '⛓', '🧰', '🧲', '🔫', '💣',
        '🧨', '🪓', '🔪', '🗡', '⚔️', '🛡', '🚬', '⚰️', '⚱️', '🏺', '🔮', '📿', '🧿', '💈', '⚗️',
      ],
    },
    Icons.favorite: {
      'Hearts': [
        '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕', '💞', '💓', '💗',
        '💖', '💘', '💝', '💟', '☮️', '✝️', '☪️', '🕉', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
      ],
      'Symbols': [
        '⚛️', '🆔', '♈️', '♉️', '♊️', '♋️', '♌️', '♍️', '♎️', '♏️', '♐️', '♑️', '♒️', '♓️', '⛎',
        '🔀', '🔁', '🔂', '▶️', '⏸', '⏯', '⏹', '⏺', '⏭', '⏮', '⏩', '⏪', '⏫', '⏬', '◀️',
      ],
    },
    Icons.flag: {
      'Countries': [
        '🏳️', '🏴', '🏁', '🚩', '🏳️‍🌈', '🏳️‍⚧️', '🇺🇳', '🇦🇫', '🇦🇽', '🇦🇱', '🇩🇿', '🇦🇸', '🇦🇩', '🇦🇴', '🇦🇮',
        '🇦🇶', '🇦🇬', '🇦🇷', '🇦🇲', '🇦🇼', '🇦🇺', '🇦🇹', '🇦🇿', '🇧🇸', '🇧🇭', '🇧🇩', '🇧🇧', '🇧🇾', '🇧🇪', '🇧🇿',
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: emojiCategories.length,
      vsync: this,
    );
    _tabController.addListener(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCategorySelector(),
          Expanded(child: _buildEmojiGrid()),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.tertiary,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 3,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.secondary,
        tabs: emojiCategories.keys.map((icon) {
          return Tab(
            child: Icon(
              icon,
              size: 24,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    return TabBarView(
      controller: _tabController,
      children: emojiCategories.entries.map((category) {
        return ListView(
          children: category.value.entries.map((subcategory) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subcategory.key.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      subcategory.key,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: subcategory.value.length,
                  itemBuilder: (context, index) {
                    return _buildEmojiButton(subcategory.value[index]);
                  },
                ),
              ],
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildEmojiButton(String emoji) {
    return InkWell(
      onTap: () => widget.onEmojiSelected(emoji),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
