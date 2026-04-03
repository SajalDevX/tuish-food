import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:tuish_food/core/enums/user_role.dart';
import 'package:tuish_food/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:tuish_food/features/customer/checkout/presentation/screens/address_selection_screen.dart';
import 'package:tuish_food/features/customer/checkout/presentation/screens/checkout_screen.dart';
import 'package:tuish_food/features/customer/checkout/domain/entities/checkout_order_draft.dart';
import 'package:tuish_food/features/customer/checkout/presentation/screens/order_confirmation_screen.dart';
import 'package:tuish_food/features/customer/checkout/presentation/screens/payment_method_screen.dart';
import 'package:tuish_food/features/customer/home/presentation/screens/customer_home_screen.dart';
import 'package:tuish_food/features/customer/home/presentation/screens/restaurant_detail_screen.dart';
import 'package:tuish_food/features/customer/home/presentation/screens/search_screen.dart';
import 'package:tuish_food/features/customer/orders/presentation/screens/order_detail_screen.dart';
import 'package:tuish_food/features/customer/orders/presentation/screens/orders_list_screen.dart';
import 'package:tuish_food/features/customer/menu/presentation/screens/menu_item_detail_screen.dart';
import 'package:tuish_food/features/customer/profile/presentation/screens/add_address_screen.dart';
import 'package:tuish_food/features/customer/profile/presentation/screens/addresses_screen.dart';
import 'package:tuish_food/features/customer/profile/presentation/screens/edit_profile_screen.dart';
import 'package:tuish_food/features/customer/profile/presentation/screens/profile_screen.dart';
import 'package:tuish_food/features/customer/profile/presentation/screens/settings_screen.dart';
import 'package:tuish_food/features/customer/reviews/presentation/screens/write_review_screen.dart';
import 'package:tuish_food/features/customer/tracking/presentation/screens/live_tracking_screen.dart';
import 'package:tuish_food/features/admin/dashboard/presentation/screens/admin_dashboard_screen.dart';
import 'package:tuish_food/features/admin/order_management/presentation/screens/all_orders_screen.dart';
import 'package:tuish_food/features/admin/order_management/presentation/screens/order_dispute_screen.dart';
import 'package:tuish_food/features/admin/promotions/presentation/screens/create_promotion_screen.dart';
import 'package:tuish_food/features/admin/promotions/presentation/screens/promotions_screen.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/screens/add_restaurant_screen.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/screens/edit_restaurant_screen.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/screens/menu_management_screen.dart';
import 'package:tuish_food/features/admin/settings/presentation/screens/admin_settings_screen.dart';
import 'package:tuish_food/features/admin/restaurant_management/presentation/screens/restaurants_list_screen.dart';
import 'package:tuish_food/features/admin/user_management/presentation/screens/delivery_partners_screen.dart';
import 'package:tuish_food/features/admin/user_management/presentation/screens/user_detail_screen.dart';
import 'package:tuish_food/features/admin/user_management/presentation/screens/users_list_screen.dart';
import 'package:tuish_food/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:tuish_food/features/auth/presentation/screens/login_screen.dart';
import 'package:tuish_food/features/auth/presentation/screens/phone_verification_screen.dart';
import 'package:tuish_food/features/auth/presentation/providers/auth_provider.dart';
import 'package:tuish_food/features/auth/presentation/screens/register_screen.dart';
import 'package:tuish_food/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:tuish_food/features/auth/presentation/screens/splash_screen.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/screens/active_delivery_screen.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/screens/available_orders_screen.dart';
import 'package:tuish_food/features/delivery/dashboard/presentation/screens/delivery_home_screen.dart';
import 'package:tuish_food/features/delivery/earnings/presentation/screens/earnings_screen.dart';
import 'package:tuish_food/features/delivery/navigation/presentation/screens/delivery_navigation_screen.dart';
import 'package:tuish_food/features/delivery/profile/presentation/screens/delivery_profile_screen.dart';
import 'package:tuish_food/features/shared/chat/presentation/screens/chat_screen.dart';
import 'package:tuish_food/features/shared/notifications/presentation/screens/notifications_screen.dart';
import 'package:tuish_food/routing/route_names.dart';
import 'package:tuish_food/routing/route_paths.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/add_menu_item_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/edit_menu_item_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/owner_menu_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/owner_order_detail_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/owner_orders_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/restaurant_profile_screen.dart';
import 'package:tuish_food/features/restaurant_owner/presentation/screens/restaurant_setup_screen.dart';
import 'package:tuish_food/routing/shell_routes/admin_shell.dart';
import 'package:tuish_food/routing/shell_routes/customer_shell.dart';
import 'package:tuish_food/routing/shell_routes/delivery_shell.dart';
import 'package:tuish_food/routing/shell_routes/restaurant_owner_shell.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(appAuthStateProvider);
  final roleAsync = ref.watch(currentUserRoleProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,

    // -------------------------------------------------------------------
    // Global redirect
    // -------------------------------------------------------------------
    redirect: (context, state) {
      if (authState.isLoading) {
        return state.uri.toString() == RoutePaths.splash
            ? null
            : RoutePaths.splash;
      }

      final isLoggedIn = authState.value != null;
      final currentPath = state.uri.toString();
      final isRoleSelectionRoute = currentPath == RoutePaths.roleSelection;
      final isAuthRoute =
          currentPath.startsWith(RoutePaths.auth) ||
          currentPath == RoutePaths.splash;
      final role = roleAsync.value;

      if (isLoggedIn && roleAsync.isLoading) {
        return currentPath == RoutePaths.splash ? null : RoutePaths.splash;
      }

      if (currentPath == RoutePaths.splash) {
        if (!isLoggedIn) {
          return RoutePaths.login;
        }
        if (role == null) {
          return RoutePaths.roleSelection;
        }
        return _homePathForRole(role);
      }

      // 1. Not logged in and not on an auth page -> redirect to login
      if (!isLoggedIn && !isAuthRoute) {
        return RoutePaths.login;
      }

      // 2. Logged in users should still be able to access role selection.
      //    All other auth routes redirect into the logged-in flow.
      if (isLoggedIn && isAuthRoute && !isRoleSelectionRoute) {
        return _landingPathForRole(role);
      }

      // 3. Role-based protection
      if (isLoggedIn) {
        if (role == null && !isRoleSelectionRoute) {
          return RoutePaths.roleSelection;
        }

        if (currentPath.startsWith('/customer') &&
            role != UserRole.customer &&
            role != null) {
          return _homePathForRole(role);
        }
        if (currentPath.startsWith('/delivery') &&
            role != UserRole.deliveryPartner &&
            role != null) {
          return _homePathForRole(role);
        }
        if (currentPath.startsWith('/restaurant') &&
            role != UserRole.restaurantOwner &&
            role != null) {
          return _homePathForRole(role);
        }
        if (currentPath.startsWith('/admin') &&
            role != UserRole.admin &&
            role != null) {
          return _homePathForRole(role);
        }
      }

      return null; // No redirect
    },

    // -------------------------------------------------------------------
    // Routes
    // -------------------------------------------------------------------
    routes: [
      // ---- Auth routes (no shell) ----
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const LoginScreen()),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const RegisterScreen()),
      ),
      GoRoute(
        path: RoutePaths.phoneVerify,
        name: RouteNames.phoneVerify,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const PhoneVerificationScreen()),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: RoutePaths.roleSelection,
        name: RouteNames.roleSelection,
        pageBuilder: (context, state) =>
            _fadeThrough(state, const RoleSelectionScreen()),
      ),

      // ---- Checkout routes (full screen, no shell) ----
      GoRoute(
        path: RoutePaths.checkout,
        name: RouteNames.checkout,
        pageBuilder: (context, state) => _slideUp(
          state,
          CheckoutScreen(
            orderDraft: state.extra is CheckoutOrderDraft
                ? state.extra as CheckoutOrderDraft
                : null,
          ),
        ),
        routes: [
          GoRoute(
            path: 'address',
            name: RouteNames.checkoutAddress,
            builder: (context, state) => const AddressSelectionScreen(),
          ),
          GoRoute(
            path: 'payment',
            name: RouteNames.checkoutPayment,
            builder: (context, state) => const PaymentMethodScreen(),
          ),
          GoRoute(
            path: 'confirmation/:orderId',
            name: RouteNames.orderConfirmation,
            builder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              return OrderConfirmationScreen(orderId: orderId);
            },
          ),
        ],
      ),

      // ---- Customer shell (bottom nav) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return CustomerShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerHome,
                name: RouteNames.customerHome,
                builder: (context, state) => const CustomerHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'restaurant/:id',
                    name: RouteNames.restaurantDetail,
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _slideUp(
                        state,
                        RestaurantDetailScreen(restaurantId: id),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'search',
                    name: RouteNames.search,
                    builder: (context, state) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'item/:itemId',
                    name: RouteNames.restaurantMenuItem,
                    builder: (context, state) {
                      final restaurantId = state.pathParameters['id']!;
                      final itemId = state.pathParameters['itemId']!;
                      return MenuItemDetailScreen(
                        restaurantId: restaurantId,
                        itemId: itemId,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerOrders,
                name: RouteNames.customerOrders,
                builder: (context, state) => const OrdersListScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: RouteNames.orderDetail,
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      return OrderDetailScreen(orderId: orderId);
                    },
                    routes: [
                      GoRoute(
                        path: 'tracking',
                        name: RouteNames.orderTracking,
                        builder: (context, state) {
                          final orderId = state.pathParameters['orderId']!;
                          return LiveTrackingScreen(orderId: orderId);
                        },
                      ),
                      GoRoute(
                        path: 'review',
                        name: RouteNames.orderReview,
                        builder: (context, state) {
                          final orderId = state.pathParameters['orderId']!;
                          return WriteReviewScreen(orderId: orderId);
                        },
                      ),
                      GoRoute(
                        path: 'chat',
                        name: RouteNames.orderChat,
                        builder: (context, state) {
                          return ChatScreen(
                            chatId: state.pathParameters['orderId'] ?? '',
                            otherUserName: 'Chat',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Cart
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerCart,
                name: RouteNames.customerCart,
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customerProfile,
                name: RouteNames.customerProfile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editProfile,
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'addresses',
                    name: RouteNames.addresses,
                    builder: (context, state) => const AddressesScreen(),
                    routes: [
                      GoRoute(
                        path: 'add',
                        name: RouteNames.addAddress,
                        builder: (context, state) => const AddAddressScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'settings',
                    name: RouteNames.customerSettings,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.customerNotifications,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),

      // ---- Delivery partner shell (bottom nav) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DeliveryShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deliveryHome,
                name: RouteNames.deliveryHome,
                builder: (context, state) => const DeliveryHomeScreen(),
              ),
            ],
          ),

          // Branch 1: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deliveryOrders,
                name: RouteNames.deliveryOrders,
                builder: (context, state) => const AvailableOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: RouteNames.deliveryOrderDetail,
                    builder: (context, state) {
                      return ActiveDeliveryScreen(
                        orderId: state.pathParameters['orderId'] ?? '',
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'navigate',
                        name: RouteNames.deliveryNavigation,
                        builder: (context, state) {
                          return DeliveryNavigationScreen(
                            orderId: state.pathParameters['orderId'] ?? '',
                          );
                        },
                      ),
                      GoRoute(
                        path: 'chat',
                        name: RouteNames.deliveryChat,
                        builder: (context, state) {
                          return ChatScreen(
                            chatId: state.pathParameters['orderId'] ?? '',
                            otherUserName: 'Chat',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Earnings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deliveryEarnings,
                name: RouteNames.deliveryEarnings,
                builder: (context, state) => const EarningsScreen(),
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deliveryProfile,
                name: RouteNames.deliveryProfile,
                builder: (context, state) => const DeliveryProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---- Restaurant setup (full screen, no shell) ----
      GoRoute(
        path: RoutePaths.restaurantSetup,
        name: RouteNames.restaurantSetup,
        pageBuilder: (context, state) =>
            _slideUp(state, const RestaurantSetupScreen()),
      ),

      // ---- Restaurant owner shell (bottom nav) ----
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return RestaurantOwnerShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.restaurantDashboard,
                name: RouteNames.restaurantDashboard,
                builder: (context, state) => const RestaurantDashboardScreen(),
              ),
            ],
          ),

          // Branch 1: Menu
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.restaurantOwnerMenu,
                name: RouteNames.restaurantOwnerMenu,
                builder: (context, state) => const OwnerMenuScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: RouteNames.restaurantAddMenuItem,
                    builder: (context, state) => const AddMenuItemScreen(),
                  ),
                  GoRoute(
                    path: ':itemId/edit',
                    name: RouteNames.restaurantEditMenuItem,
                    builder: (context, state) {
                      final itemId = state.pathParameters['itemId']!;
                      return EditMenuItemScreen(itemId: itemId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Orders
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.restaurantOrders,
                name: RouteNames.restaurantOrders,
                builder: (context, state) => const OwnerOrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':orderId',
                    name: RouteNames.restaurantOrderDetail,
                    builder: (context, state) {
                      final orderId = state.pathParameters['orderId']!;
                      return OwnerOrderDetailScreen(orderId: orderId);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.restaurantProfile,
                name: RouteNames.restaurantProfile,
                builder: (context, state) => const RestaurantProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---- Admin shell (drawer navigation) ----
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: RoutePaths.adminDashboard,
            name: RouteNames.adminDashboard,
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminRestaurants,
            name: RouteNames.adminRestaurants,
            builder: (context, state) => const RestaurantsListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.addRestaurant,
                builder: (context, state) => const AddRestaurantScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                name: RouteNames.editRestaurant,
                builder: (context, state) {
                  return EditRestaurantScreen(
                    restaurantId: state.pathParameters['id'] ?? '',
                  );
                },
              ),
              GoRoute(
                path: ':id/menu',
                name: RouteNames.restaurantMenu,
                builder: (context, state) {
                  return MenuManagementScreen(
                    restaurantId: state.pathParameters['id'] ?? '',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.adminUsers,
            name: RouteNames.adminUsers,
            builder: (context, state) => const UsersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: RouteNames.adminUserDetail,
                builder: (context, state) {
                  return UserDetailScreen(
                    userId: state.pathParameters['id'] ?? '',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.adminDeliveryPartners,
            name: RouteNames.adminDeliveryPartners,
            builder: (context, state) => const DeliveryPartnersScreen(),
          ),
          GoRoute(
            path: RoutePaths.adminOrders,
            name: RouteNames.adminOrders,
            builder: (context, state) => const AllOrdersScreen(),
            routes: [
              GoRoute(
                path: ':orderId',
                name: RouteNames.adminOrderDetail,
                builder: (context, state) {
                  return OrderDisputeScreen(
                    orderId: state.pathParameters['orderId'] ?? '',
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.adminPromotions,
            name: RouteNames.adminPromotions,
            builder: (context, state) => const PromotionsScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: RouteNames.createPromotion,
                builder: (context, state) => const CreatePromotionScreen(),
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.adminSettings,
            name: RouteNames.adminSettings,
            builder: (context, state) => const AdminSettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns the home path for the given role, defaulting to customer home
/// when the role is not yet determined.
String _homePathForRole(UserRole? role) {
  return switch (role) {
    UserRole.customer => RoutePaths.customerHome,
    UserRole.deliveryPartner => RoutePaths.deliveryHome,
    UserRole.restaurantOwner => RoutePaths.restaurantDashboard,
    UserRole.admin => RoutePaths.adminDashboard,
    null => RoutePaths.roleSelection,
  };
}

String _landingPathForRole(UserRole? role) {
  return role == null ? RoutePaths.roleSelection : _homePathForRole(role);
}

CustomTransitionPage<void> _fadeThrough(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideUp(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (_, animation, _, child) {
      final tween = Tween(
        begin: const Offset(0, 0.15),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Placeholder screen
// ---------------------------------------------------------------------------
