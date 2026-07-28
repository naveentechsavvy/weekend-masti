import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../utils/colors.dart';
import 'search_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'restaurant_detail_screen.dart'; // contains CartManager
import 'meetup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedCategory = -1; // -1 = no filter, show all restaurants
  int _currentBanner = 0;
  int _bottomIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=100',
      'name': 'Pizza'
    },
    {
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=100',
      'name': 'Burger'
    },
    {
      'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=100',
      'name': 'Noodles'
    },
    {
      'image': 'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=100',
      'name': 'Chicken'
    },
    {
      'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=100',
      'name': 'Salad'
    },
    {
      'image': 'https://images.unsplash.com/photo-1551024601-bec78aea704b?w=100',
      'name': 'Dessert'
    },
    {
      'image': 'https://images.unsplash.com/photo-1544145945-f90425340c7e?w=100',
      'name': 'Drinks'
    },
    {
      'image': 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=100',
      'name': 'Sushi'
    },
  ];

  final List<Map<String, dynamic>> _banners = [
    {
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      'title': '50% OFF',
      'sub': 'On your first order',
      'color': Color(0xCCFF6B00),
    },
    {
      'image': 'https://images.unsplash.com/photo-1565299507177-b0ac66763828?w=800',
      'title': 'Free Delivery',
      'sub': 'Orders above ₹299',
      'color': Color(0xCC6C63FF),
    },
    {
      'image': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800',
      'title': 'Weekend Special',
      'sub': 'Exclusive deals today',
      'color': Color(0xCC00BFA5),
    },
  ];

  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Burger Palace',
      'cuisine': 'Burgers • Fast Food • American',
      'rating': '4.5',
      'time': '25-30 min',
      'price': '₹200 for two',
      'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
      'tag': 'BESTSELLER',
      'discount': '20% OFF',
      'items': [
        {'name': 'Classic Burger', 'price': 120, 'emoji': '🍔', 'desc': 'Juicy beef patty with fresh veggies'},
        {'name': 'Cheese Burst', 'price': 150, 'emoji': '🧀', 'desc': 'Extra cheese loaded burger'},
        {'name': 'Chicken Burger', 'price': 140, 'emoji': '🍗', 'desc': 'Crispy chicken with mayo'},
        {'name': 'French Fries', 'price': 80, 'emoji': '🍟', 'desc': 'Crispy golden fries'},
        {'name': 'Cold Drink', 'price': 60, 'emoji': '🥤', 'desc': 'Chilled beverage'},
      ],
    },
    {
      'name': 'Pizza House',
      'cuisine': 'Pizza • Italian • Pasta',
      'rating': '4.3',
      'time': '30-35 min',
      'price': '₹350 for two',
      'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600',
      'tag': 'NEW',
      'discount': 'Free Delivery',
      'items': [
        {'name': 'Margherita Pizza', 'price': 250, 'emoji': '🍕', 'desc': 'Classic tomato and cheese'},
        {'name': 'Pepperoni Pizza', 'price': 320, 'emoji': '🍕', 'desc': 'Loaded with pepperoni'},
        {'name': 'Pasta Alfredo', 'price': 200, 'emoji': '🍝', 'desc': 'Creamy white sauce pasta'},
        {'name': 'Garlic Bread', 'price': 90, 'emoji': '🥖', 'desc': 'Toasted garlic bread'},
      ],
    },
    {
      'name': 'Biryani Bros',
      'cuisine': 'Biryani • North Indian • Kebabs',
      'rating': '4.7',
      'time': '40-45 min',
      'price': '₹450 for two',
      'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=600',
      'tag': 'TOP RATED',
      'discount': '₹100 OFF',
      'items': [
        {'name': 'Chicken Biryani', 'price': 220, 'emoji': '🍛', 'desc': 'Aromatic basmati rice with chicken'},
        {'name': 'Mutton Biryani', 'price': 280, 'emoji': '🍛', 'desc': 'Tender mutton biryani'},
        {'name': 'Veg Biryani', 'price': 180, 'emoji': '🥘', 'desc': 'Fresh vegetable biryani'},
        {'name': 'Seekh Kebab', 'price': 160, 'emoji': '🍢', 'desc': 'Spicy minced meat kebab'},
        {'name': 'Raita', 'price': 50, 'emoji': '🥣', 'desc': 'Cooling yogurt side'},
      ],
    },
    {
      'name': 'Noodle Nation',
      'cuisine': 'Chinese • Thai • Asian',
      'rating': '4.2',
      'time': '20-25 min',
      'price': '₹300 for two',
      'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
      'tag': 'TRENDING',
      'discount': '15% OFF',
      'items': [
        {'name': 'Hakka Noodles', 'price': 140, 'emoji': '🍜', 'desc': 'Stir fried noodles'},
        {'name': 'Fried Rice', 'price': 130, 'emoji': '🍚', 'desc': 'Wok tossed fried rice'},
        {'name': 'Manchurian', 'price': 150, 'emoji': '🥡', 'desc': 'Crispy balls in sauce'},
        {'name': 'Spring Rolls', 'price': 110, 'emoji': '🥟', 'desc': 'Crispy veggie rolls'},
      ],
    },
    {
      'name': 'South Spice',
      'cuisine': 'South Indian • Dosa • Idli',
      'rating': '4.4',
      'time': '25-30 min',
      'price': '₹200 for two',
      'image': 'https://images.unsplash.com/photo-1630383249896-424e482df921?w=600',
      'tag': 'MUST TRY',
      'discount': '25% OFF',
      'items': [
        {'name': 'Masala Dosa', 'price': 90, 'emoji': '🫓', 'desc': 'Crispy dosa with potato filling'},
        {'name': 'Idli Sambar', 'price': 70, 'emoji': '🍱', 'desc': 'Soft idlis with sambar'},
        {'name': 'Vada', 'price': 60, 'emoji': '🍩', 'desc': 'Crispy medu vada'},
        {'name': 'Filter Coffee', 'price': 40, 'emoji': '☕', 'desc': 'Strong south indian coffee'},
        {'name': 'Uttapam', 'price': 100, 'emoji': '🥞', 'desc': 'Thick rice pancake'},
      ],
    },
  ];

  // ---------------------------------------------------------
  // Returns restaurants matching the selected category.
  // Matches against the restaurant's cuisine string first,
  // then falls back to checking individual menu item names.
  // If no category is selected (-1), returns everything.
  // ---------------------------------------------------------
  List<Map<String, dynamic>> get _filteredRestaurants {
    if (_selectedCategory == -1) return restaurants;

    final categoryName =
        _categories[_selectedCategory]['name'].toString().toLowerCase();

    return restaurants.where((r) {
      final cuisine = (r['cuisine'] ?? '').toString().toLowerCase();
      if (cuisine.contains(categoryName)) return true;

      final items = (r['items'] as List?) ?? [];
      return items.any((item) => (item['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(categoryName));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: _buildBottomNav(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_bottomIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return SearchScreen();
      case 2:
        return const CartScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 800));
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildOfferStrip(),
              _buildBannerSlider(),
              _buildCategories(),
              _buildSectionTitle(
                _selectedCategory == -1
                    ? '🔥 Top Restaurants near you'
                    : '${_categories[_selectedCategory]['name']} Restaurants',
                'See all',
              ),
              _buildRestaurantList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Home - Hyderabad',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark)),
                      Icon(Icons.keyboard_arrow_down,
                          color: AppColors.textDark, size: 20),
                    ],
                  ),
                  Text('Telangana, India',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Meet Up icon — lets users jump back into the Meet Up flow
          // from anywhere inside the food-ordering experience.
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MeetupScreen()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded,
                    color: Color(0xFF6C63FF), size: 20),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Cart icon with live badge count
          GestureDetector(
            onTap: () => setState(() => _bottomIndex = 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      color: AppColors.textDark, size: 24),
                  if (CartManager.totalItems > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${CartManager.totalItems}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _bottomIndex = 3),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Icon(Icons.person, color: AppColors.primary, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- SEARCH BAR ----------
  Widget _buildSearchBar() {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => setState(() => _bottomIndex = 1),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.textGrey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Restaurant name, item or cuisine',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
              ),
              Container(
                height: 22,
                width: 1,
                color: AppColors.divider,
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- THIN OFFER STRIP ----------
  Widget _buildOfferStrip() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.local_offer_rounded, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Free delivery on orders above ₹299 • Use code FIRST50',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- BANNER SLIDER ----------
  Widget _buildBannerSlider() {
    return Column(
      children: [
        const SizedBox(height: 12),
        CarouselSlider(
          options: CarouselOptions(
            height: 165,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.92,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, _) => setState(() => _currentBanner = index),
          ),
          items: _banners.map((banner) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: banner['image'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppColors.divider),
                    errorWidget: (context, url, error) =>
                        Container(color: AppColors.divider),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerRight,
                        end: Alignment.centerLeft,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.72),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(banner['title'],
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3)),
                        const SizedBox(height: 4),
                        Text(banner['sub'],
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Text('Order Now',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _banners.asMap().entries.map((e) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: _currentBanner == e.key ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: _currentBanner == e.key
                    ? AppColors.primary
                    : AppColors.textLight,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------- CATEGORIES ----------
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text("What's on your mind?",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 104,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedCategory == index;
              return GestureDetector(
                // Tapping the already-selected category clears the filter
                // (acts as a toggle); tapping a new one applies it.
                onTap: () => setState(() {
                  _selectedCategory = _selectedCategory == index ? -1 : index;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: CachedNetworkImage(
                            imageUrl: _categories[index]['image'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: AppColors.divider),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.divider,
                              child: Icon(Icons.fastfood,
                                  color: AppColors.textGrey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(_categories[index]['name'],
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textGrey)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, String action) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(action,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------- RESTAURANT LIST ----------
  Widget _buildRestaurantList() {
    final list = _filteredRestaurants;

    // Empty state — shown when the selected category matches no restaurants
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textGrey),
              const SizedBox(height: 10),
              Text(
                'No restaurants found for "${_categories[_selectedCategory]['name']}"',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => setState(() => _selectedCategory = -1),
                child: Text('Clear filter',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final r = list[index];
        return _RestaurantCard(
          data: r,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RestaurantDetailScreen(restaurant: r),
              ),
            );
          },
        );
      },
    );
  }

  // ---------- BOTTOM NAV ----------
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: _bottomIndex,
          onTap: (index) => setState(() => _bottomIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textGrey,
          backgroundColor: AppColors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.search_rounded), label: 'Search'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_rounded),
                  if (CartManager.totalItems > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${CartManager.totalItems}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Cart',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// Restaurant card with a quick-add button for the first menu
// item, so users can add to cart without opening the
// restaurant page — same pattern as Swiggy/Zomato cards.
// =========================================================
class _RestaurantCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _RestaurantCard({required this.data, required this.onTap});

  @override
  State<_RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<_RestaurantCard> {
  double _scale = 1;

  void _setScale(double value) => setState(() => _scale = value);

  void _showAddedSnackBar(String itemName) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$itemName added to cart'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.data;
    final items = (r['items'] as List?) ?? [];
    final Map<String, dynamic>? featuredItem =
        items.isNotEmpty ? items[0] as Map<String, dynamic> : null;
    final qty =
        featuredItem != null ? CartManager.getQty(featuredItem['name']) : 0;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setScale(0.97),
      onTapUp: (_) => _setScale(1),
      onTapCancel: () => _setScale(1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 14,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(18)),
                    child: CachedNetworkImage(
                      imageUrl: r['image'],
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 170,
                        color: AppColors.divider,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 170,
                        color: AppColors.divider,
                        child: Icon(Icons.restaurant,
                            size: 50, color: AppColors.textGrey),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.55),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer,
                              color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(r['discount'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Text(r['tag'] ?? '',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_border,
                          size: 16, color: AppColors.textGrey),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(r['name'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 3),
                              Text(r['rating'] ?? '',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(r['cuisine'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textGrey)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 4),
                        Text(r['time'] ?? '',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textGrey)),
                        const SizedBox(width: 4),
                        Text('•',
                            style: TextStyle(color: AppColors.textLight)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(r['price'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textGrey)),
                        ),
                      ],
                    ),

                    // ---------- QUICK ADD-TO-CART ROW ----------
                    if (featuredItem != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(featuredItem['emoji'] ?? '🍽️',
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(featuredItem['name'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textDark)),
                                  Text('₹${featuredItem['price']}',
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textGrey)),
                                ],
                              ),
                            ),
                            // tap stops the card's own onTap from firing
                            GestureDetector(
                              onTap: () {},
                              child: qty == 0
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          CartManager.addItem(
                                              featuredItem, r['name']);
                                        });
                                        _showAddedSnackBar(
                                            featuredItem['name']);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 16, vertical: 6),
                                        minimumSize: Size.zero,
                                        textStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800),
                                      ),
                                      child: const Text('ADD'),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove,
                                                size: 14, color: Colors.white),
                                            onPressed: () => setState(() =>
                                                CartManager.removeItem(
                                                    featuredItem['name'])),
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 28,
                                                    minHeight: 28),
                                            padding: EdgeInsets.zero,
                                          ),
                                          Text('$qty',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                  fontSize: 13)),
                                          IconButton(
                                            icon: const Icon(Icons.add,
                                                size: 14, color: Colors.white),
                                            onPressed: () {
                                              setState(() =>
                                                  CartManager.addItem(
                                                      featuredItem,
                                                      r['name']));
                                              _showAddedSnackBar(
                                                  featuredItem['name']);
                                            },
                                            constraints:
                                                const BoxConstraints(
                                                    minWidth: 28,
                                                    minHeight: 28),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
