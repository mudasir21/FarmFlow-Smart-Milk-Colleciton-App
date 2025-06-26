import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import './farmer_main_screen.dart';
import './farmer_profile_screen.dart';
import '/screens/login_screen.dart';
import '../services/auth_service.dart';
import '../helpers/available_distributors_screen.dart';
import '../helpers/FarmerStatisticsScreen.dart';
import '../helpers/milk_collection_screen.dart';
import '../helpers/distributor_prices_screen.dart';
import '../helpers/farmer_scheduled_pickups_screen.dart';

// Constants for maintainability
const double _gridMaxCrossAxisExtent = 200.0;
const String _appName = 'Dairy Connect';

class HomeScreenFarmer extends StatefulWidget {
  const HomeScreenFarmer({Key? key}) : super(key: key);

  @override
  State<HomeScreenFarmer> createState() => _HomeScreenFarmerState();
}

class _HomeScreenFarmerState extends State<HomeScreenFarmer> {
  int _selectedIndex = 0;
  String farmerName = 'Loading...';
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmerData(); // Fetch farmer name on initialization
  }

  Future<void> _loadFarmerData() async {
    setState(() {
      farmerName = 'Loading...';
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('User UID: ${user?.uid}');
      if (user == null) {
        setState(() {
          farmerName = 'Farmer';
          errorMessage = 'No user is logged in. Please sign in again.';
        });
        return;
      }

      // Fetch farmer profile
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      print('Farmer Doc Exists: ${farmerDoc.exists}');
      print('Farmer Data: ${farmerDoc.data()}');

      String name = 'Farmer';
      if (farmerDoc.exists) {
        final data = farmerDoc.data() as Map<String, dynamic>?;
        name = data?['firstName'] ?? user.displayName ?? 'Farmer';
      } else {
        name = user.displayName ?? user.email?.split('@')[0] ?? 'Farmer';
      }

      // Capitalize name for consistency
      name = name
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');

      setState(() {
        farmerName = name;
      });
    } catch (e) {
      String error;
      if (e.toString().contains('permission-denied')) {
        error = 'Permission denied. Please check your access rights.';
      } else if (e.toString().contains('network')) {
        error = 'Network error. Please check your internet connection.';
      } else {
        error = 'Failed to load profile: $e';
      }
      print('Error loading farmer data: $e');
      setState(() {
        farmerName = 'Farmer';
        errorMessage = error;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          _appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildBeautifulDrawer(context),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Pickups',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            elevation: 0,
            backgroundColor: Colors.white,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }

  Widget _buildBeautifulDrawer(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final photoUrl = user?.photoURL;

    return Drawer(
      child: Container(
        color: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? const Icon(Icons.person, size: 40, color: Colors.green)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Welcome, $farmerName',
                    child: Text(
                      'Welcome, $farmerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Manage your dairy business',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.dashboard,
              title: 'Dashboard',
              onTap: () => _onItemTapped(0),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.person,
              title: 'Profile',
              onTap: () => _onItemTapped(1),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.calendar_today,
              title: 'Scheduled Pickups',
              onTap: () => _onItemTapped(2),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MILK MANAGEMENT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.analytics,
              title: 'My Statistics',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FarmerStatisticsScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.store,
              title: 'View Distributors',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DistributorPricesScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ACCOUNT',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildDrawerItem(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Support coming soon!")),
                );
              },
            ),
            _buildDrawerItem(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AuthService().signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const SignInPage()),
                    (Route<dynamic> route) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logged out successfully!")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Logout failed: $e")),
                  );
                }
              },
              textColor: Colors.red,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Semantics(
      label: title,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.green),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        dense: true,
      ),
    );
  }

  // Updated pages list with Dashboard, Profile, and Scheduled Pickups
  static final List<Widget> _pages = <Widget>[
    DashboardPage(),
    FarmerProfileScreen(),
    FarmerScheduledPickupsScreen(),
  ];
}

// Placeholder Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String farmerName = 'Loading...';
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFarmerData();
  }

  Future<void> _loadFarmerData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      print('User UID: ${user?.uid}');
      if (user == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No user is logged in. Please sign in again.';
          farmerName = 'Farmer';
        });
        return;
      }

      // Fetch farmer profile
      final farmerDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .get();
      print('Farmer Doc Exists: ${farmerDoc.exists}');
      print('Farmer Data: ${farmerDoc.data()}');

      String name = 'Farmer';
      if (farmerDoc.exists) {
        final data = farmerDoc.data() as Map<String, dynamic>?;
        name = data?['firstName'] ?? user.displayName ?? 'Farmer';
      } else {
        name = user.displayName ?? user.email?.split('@')[0] ?? 'Farmer';
      }

      // Capitalize name for consistency
      name = name
          .split(' ')
          .map((word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : '')
          .join(' ');

      setState(() {
        farmerName = name;
        isLoading = false;
      });
    } catch (e) {
      String error;
      if (e.toString().contains('permission-denied')) {
        error = 'Permission denied. Please check your access rights.';
      } else if (e.toString().contains('network')) {
        error = 'Network error. Please check your internet connection.';
      } else {
        error = 'Failed to load profile: $e';
      }
      print('Error loading farmer data: $e');
      setState(() {
        farmerName = 'Farmer';
        isLoading = false;
        errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final formattedTime = DateFormat('h:mm a').format(now);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            errorMessage != null
                ? _buildErrorBanner(errorMessage!)
                : _buildWelcomeBanner(formattedDate, formattedTime),
            const SizedBox(height: 20),
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 10),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width,
              ),
              child: GridView.extent(
                maxCrossAxisExtent: _gridMaxCrossAxisExtent,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildFeatureCard(
                    title: 'My Statistics',
                    icon: Icons.analytics,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerStatisticsScreen(),
                        ),
                      );
                    },
                    description: 'View your milk production data',
                  ),
                  _buildFeatureCard(
                    title: 'View Distributors',
                    icon: Icons.store,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DistributorPricesScreen(),
                        ),
                      );
                    },
                    description: 'See available milk distributors',
                  ),
                  _buildFeatureCard(
                    title: 'Scheduled Pickups',
                    icon: Icons.calendar_today,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FarmerScheduledPickupsScreen(),
                        ),
                      );
                    },
                    description: 'View your upcoming pickups',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Recent Activity'),
            const SizedBox(height: 10),
            _buildRecentActivityCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String formattedDate, String formattedTime) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green, Colors.green.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'Welcome back, $farmerName',
            child: Text(
              'Welcome back, $farmerName!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Date and time: $formattedDate, $formattedTime IST',
            child: Text(
              '$formattedDate, $formattedTime IST',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Error',
            style: TextStyle(
              color: Colors.red,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFarmerData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String description,
  }) {
    return Semantics(
      label: title,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minWidth: 0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history, color: Colors.grey, size: 48),
              const SizedBox(height: 8),
              Text(
                'No transactions available',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




// // ------------------------------------//

// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import './farmer_main_screen.dart';
// import './farmer_profile_screen.dart';
// import '/screens/login_screen.dart';
// import '../services/auth_service.dart';
// import '../helpers/available_distributors_screen.dart';
// import '../helpers/FarmerStatisticsScreen.dart';
// import '../helpers/milk_collection_screen.dart';
// import '../helpers/distributor_prices_screen.dart';
// import '../helpers/farmer_scheduled_pickups_screen.dart';

// // Constants for maintainability
// const double _gridMaxCrossAxisExtent = 200.0;
// const String _appName = 'Dairy Connect';

// class HomeScreenFarmer extends StatefulWidget {
//   const HomeScreenFarmer({Key? key}) : super(key: key);

//   @override
//   State<HomeScreenFarmer> createState() => _HomeScreenFarmerState();
// }

// class _HomeScreenFarmerState extends State<HomeScreenFarmer> {
//   int _selectedIndex = 0;

//   // Updated pages list with Dashboard, Profile, and Scheduled Pickups
//   static final List<Widget> _pages = <Widget>[
//     DashboardPage(),
//     FarmerProfileScreen(),
//     FarmerScheduledPickupsScreen(),
//   ];

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           _appName,
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.green,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const NotificationsScreen(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       drawer: _buildBeautifulDrawer(context),
//       body: _pages[_selectedIndex],
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               offset: const Offset(0, -5),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//           child: BottomNavigationBar(
//             items: const <BottomNavigationBarItem>[
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.dashboard_outlined),
//                 activeIcon: Icon(Icons.dashboard),
//                 label: 'Dashboard',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person_outline),
//                 activeIcon: Icon(Icons.person),
//                 label: 'Profile',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.calendar_today_outlined),
//                 activeIcon: Icon(Icons.calendar_today),
//                 label: 'Pickups',
//               ),
//             ],
//             currentIndex: _selectedIndex,
//             selectedItemColor: Colors.green,
//             unselectedItemColor: Colors.grey,
//             selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
//             elevation: 0,
//             backgroundColor: Colors.white,
//             onTap: _onItemTapped,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildBeautifulDrawer(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//     final photoUrl = user?.photoURL;

//     return Drawer(
//       child: Container(
//         color: Colors.white,
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.green, Color(0xFF388E3C)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.white,
//                     backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
//                     child: photoUrl == null
//                         ? const Icon(Icons.person, size: 40, color: Colors.green)
//                         : null,
//                   ),
//                   const SizedBox(height: 10),
//                   const Text(
//                     'Welcome, Farmer',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Text(
//                     'Manage your dairy business',
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.8),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.dashboard,
//               title: 'Dashboard',
//               onTap: () => _onItemTapped(0),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.person,
//               title: 'Profile',
//               onTap: () => _onItemTapped(1),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.calendar_today,
//               title: 'Scheduled Pickups',
//               onTap: () => _onItemTapped(2),
//             ),
//             const Divider(),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Text(
//                 'MILK MANAGEMENT',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.analytics,
//               title: 'My Statistics',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const FarmerStatisticsScreen(),
//                   ),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.store,
//               title: 'View Distributors',
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const DistributorPricesScreen(),
//                   ),
//                 );
//               },
//             ),
//             // _buildDrawerItem(
//             //   context,
//             //   icon: Icons.local_shipping,
//             //   title: 'Schedule Collection',
//             //   onTap: () {
//             //     Navigator.pop(context);
//             //     Navigator.push(
//             //       context,
//             //       MaterialPageRoute(
//             //         builder: (context) => MilkCollectionScreen(userRole: 'farmer'),
//             //       ),
//             //     );
//             //   },
//             // ),
//             const Divider(),
//             const Padding(
//               padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               child: Text(
//                 'ACCOUNT',
//                 style: TextStyle(
//                   color: Colors.grey,
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.help_outline,
//               title: 'Help & Support',
//               onTap: () {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Support coming soon!")),
//                 );
//               },
//             ),
//             _buildDrawerItem(
//               context,
//               icon: Icons.logout,
//               title: 'Logout',
//               onTap: () async {
//                 Navigator.pop(context);
//                 try {
//                   await AuthService().signOut();
//                   Navigator.of(context).pushAndRemoveUntil(
//                     MaterialPageRoute(builder: (context) => const SignInPage()),
//                     (Route<dynamic> route) => false,
//                   );
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Logged out successfully!")),
//                   );
//                 } catch (e) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text("Logout failed: $e")),
//                   );
//                 }
//               },
//               textColor: Colors.red,
//               iconColor: Colors.red,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDrawerItem(
//     BuildContext context, {
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color? textColor,
//     Color? iconColor,
//   }) {
//     return Semantics(
//       label: title,
//       child: ListTile(
//         leading: Icon(icon, color: iconColor ?? Colors.green),
//         title: Text(
//           title,
//           style: TextStyle(
//             color: textColor ?? Colors.black87,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         onTap: onTap,
//         contentPadding: const EdgeInsets.symmetric(horizontal: 24),
//         dense: true,
//       ),
//     );
//   }
// }

// // Placeholder Notifications Screen
// class NotificationsScreen extends StatelessWidget {
//   const NotificationsScreen({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Notifications'),
//         backgroundColor: Colors.green,
//       ),
//       body: const Center(
//         child: Text(
//           'No notifications yet',
//           style: TextStyle(fontSize: 16, color: Colors.grey),
//         ),
//       ),
//     );
//   }
// }

// class DashboardPage extends StatefulWidget {
//   @override
//   _DashboardPageState createState() => _DashboardPageState();
// }

// class _DashboardPageState extends State<DashboardPage> {
//   String farmerName = 'Farmer';
//   bool isLoading = true;
//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadFarmerData();
//   }

//   Future<void> _loadFarmerData() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final user = FirebaseAuth.instance.currentUser;

//       if (user == null) {
//         setState(() {
//           isLoading = false;
//           errorMessage = 'No user is logged in. Please sign in again.';
//         });
//         return;
//       }

//       // Fetch farmer profile
//       final farmerDoc = await FirebaseFirestore.instance
//           .collection('farmers')
//           .doc(user.uid)
//           .get();

//       String name = 'Farmer';
//       if (farmerDoc.exists) {
//         final data = farmerDoc.data() as Map<String, dynamic>?;
//         name = data?['firstName'] ?? user.displayName ?? 'Farmer';
//       } else {
//         name = user.displayName ?? 'Farmer';
//       }

//       setState(() {
//         farmerName = name;
//         isLoading = false;
//       });
//     } catch (e) {
//       String error;
//       if (e.toString().contains('permission-denied')) {
//         error = 'Permission denied. Please check your access rights.';
//       } else if (e.toString().contains('network')) {
//         error = 'Network error. Please check your internet connection.';
//       } else {
//         error = 'Failed to load profile: $e';
//       }
//       print('Error loading farmer data: $e');
//       setState(() {
//         farmerName = 'Farmer';
//         isLoading = false;
//         errorMessage = error;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(now);
//     final formattedTime = DateFormat('h:mm a').format(now);

//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             errorMessage != null
//                 ? _buildErrorBanner(errorMessage!)
//                 : _buildWelcomeBanner(formattedDate, formattedTime),
//             const SizedBox(height: 20),
//             _buildSectionTitle('Quick Actions'),
//             const SizedBox(height: 10),
//             Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width,
//               ),
//               child: GridView.extent(
//                 maxCrossAxisExtent: _gridMaxCrossAxisExtent,
//                 childAspectRatio: 0.85,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 shrinkWrap: true,
//                 physics: const NeverScrollableScrollPhysics(),
//                 children: [
//                   _buildFeatureCard(
//                     title: 'My Statistics',
//                     icon: Icons.analytics,
//                     color: Colors.blue,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const FarmerStatisticsScreen(),
//                         ),
//                       );
//                     },
//                     description: 'View your milk production data',
//                   ),
//                   _buildFeatureCard(
//                     title: 'View Distributors',
//                     icon: Icons.store,
//                     color: Colors.green,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const DistributorPricesScreen(),
//                         ),
//                       );
//                     },
//                     description: 'See available milk distributors',
//                   ),
//                   _buildFeatureCard(
//                     title: 'Scheduled Pickups',
//                     icon: Icons.calendar_today,
//                     color: Colors.orange,
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => const FarmerScheduledPickupsScreen(),
//                         ),
//                       );
//                     },
//                     description: 'View your upcoming pickups',
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             _buildSectionTitle('Recent Activity'),
//             const SizedBox(height: 10),
//             _buildRecentActivityCard(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildWelcomeBanner(String formattedDate, String formattedTime) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.green, Colors.green.shade800],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.green.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Semantics(
//             label: 'Welcome back, $farmerName',
//             child: Text(
//               'Welcome back, $farmerName!',
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Semantics(
//             label: 'Date and time: $formattedDate, $formattedTime IST',
//             child: Text(
//               '$formattedDate, $formattedTime IST',
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.9),
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorBanner(String message) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.red.shade100,
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.red.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Error',
//             style: TextStyle(
//               color: Colors.red,
//               fontSize: 22,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             message,
//             style: TextStyle(
//               color: Colors.red.shade900,
//               fontSize: 14,
//             ),
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _loadFarmerData,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Retry'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 20,
//           decoration: BoxDecoration(
//             color: Colors.green,
//             borderRadius: BorderRadius.circular(4),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.black87,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildFeatureCard({
//     required String title,
//     required IconData icon,
//     required Color color,
//     required VoidCallback onTap,
//     required String description,
//   }) {
//     return Semantics(
//       label: title,
//       button: true,
//       child: GestureDetector(
//         onTap: onTap,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           constraints: const BoxConstraints(minWidth: 0),
//           child: Card(
//             elevation: 2,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: InkWell(
//               onTap: onTap,
//               borderRadius: BorderRadius.circular(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: color.withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(icon, color: color, size: 32),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       title,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       description,
//                       style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildRecentActivityCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Center(
//           child: Column(
//             children: [
//               const Icon(Icons.history, color: Colors.grey, size: 48),
//               const SizedBox(height: 8),
//               Text(
//                 'No transactions available',
//                 style: TextStyle(color: Colors.grey.shade600),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }