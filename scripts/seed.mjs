/**
 * Tuish Food - Firebase Seed Script
 *
 * Seeds Firestore with sample data and creates auth users with custom claims.
 * Run: cd scripts && npm install && node seed.mjs
 */

import { initializeApp, cert } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue, GeoPoint } from "firebase-admin/firestore";

initializeApp({
  credential: cert("./service-account.json"),
});

const auth = getAuth();
const db = getFirestore();

// ─── Test Accounts ───────────────────────────────────────────────────────────

const TEST_USERS = [
  {
    email: "admin@tuishfood.com",
    password: "Admin@123",
    displayName: "Sajal Admin",
    role: "admin",
  },
  {
    email: "customer@tuishfood.com",
    password: "Customer@123",
    displayName: "Test Customer",
    role: "customer",
  },
  {
    email: "driver@tuishfood.com",
    password: "Driver@123",
    displayName: "Test Driver",
    role: "deliveryPartner",
  },
  {
    email: "owner@tuishfood.com",
    password: "Owner@123",
    displayName: "Test Restaurant Owner",
    role: "restaurantOwner",
  },
];

// ─── Sample Restaurants ──────────────────────────────────────────────────────

const RESTAURANTS = [
  {
    id: "rest_biryani_house",
    name: "Royal Biryani House",
    description:
      "Authentic Hyderabadi biryani and kebabs made with traditional recipes.",
    cuisineTypes: ["Indian", "Biryani", "Mughlai"],
    tags: ["biryani", "kebab", "mughlai", "indian"],
    averageRating: 4.5,
    totalRatings: 128,
    totalOrders: 1250,
    deliveryFee: 30,
    freeDeliveryAbove: 500,
    preparationTimeMinutes: 35,
    minimumOrderAmount: 150,
    priceLevel: 2,
    isActive: true,
    isOpen: true,
    isFeatured: true,
    address: {
      addressLine1: "123 Food Street, Sector 18, Noida",
      city: "Noida",
      state: "UP",
      location: { latitude: 28.5706, longitude: 77.321 },
    },
    operatingHours: [
      { day: "Monday", openTime: "10:00", closeTime: "23:00", isClosed: false },
      { day: "Tuesday", openTime: "10:00", closeTime: "23:00", isClosed: false },
      { day: "Wednesday", openTime: "10:00", closeTime: "23:00", isClosed: false },
      { day: "Thursday", openTime: "10:00", closeTime: "23:00", isClosed: false },
      { day: "Friday", openTime: "10:00", closeTime: "23:00", isClosed: false },
      { day: "Saturday", openTime: "10:00", closeTime: "23:30", isClosed: false },
      { day: "Sunday", openTime: "10:00", closeTime: "23:30", isClosed: false },
    ],
    phone: "+91-9876543210",
    imageUrl: "",
    coverImageUrl: "",
    categories: [
      { id: "cat_biryani", name: "Biryani", sortOrder: 0 },
      { id: "cat_starters", name: "Starters", sortOrder: 1 },
      { id: "cat_beverages", name: "Beverages", sortOrder: 2 },
    ],
    menuItems: [
      {
        id: "item_chicken_biryani",
        categoryId: "cat_biryani",
        name: "Chicken Biryani",
        description: "Fragrant basmati rice layered with tender chicken and aromatic spices",
        price: 280,
        discountedPrice: 249,
        imageUrl: "",
        isAvailable: true,
        isVeg: false,
        isPopular: true,
        preparationTime: 25,
        customizations: [],
      },
      {
        id: "item_mutton_biryani",
        categoryId: "cat_biryani",
        name: "Mutton Biryani",
        description: "Slow-cooked mutton pieces with saffron-infused rice",
        price: 380,
        imageUrl: "",
        isAvailable: true,
        isVeg: false,
        isPopular: true,
        preparationTime: 30,
        customizations: [
          {
            id: "cust_size",
            name: "Portion Size",
            type: "single",
            required: true,
            options: [
              { id: "opt_half", name: "Half", price: 0 },
              { id: "opt_full", name: "Full", price: 150 },
            ],
          },
        ],
      },
      {
        id: "item_veg_biryani",
        categoryId: "cat_biryani",
        name: "Veg Biryani",
        description: "Mixed vegetables with fragrant rice and herbs",
        price: 199,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 20,
        customizations: [],
      },
      {
        id: "item_seekh_kebab",
        categoryId: "cat_starters",
        name: "Seekh Kebab (6 pcs)",
        description: "Minced lamb kebabs grilled on skewers",
        price: 220,
        imageUrl: "",
        isAvailable: true,
        isVeg: false,
        isPopular: true,
        preparationTime: 15,
        customizations: [],
      },
      {
        id: "item_paneer_tikka",
        categoryId: "cat_starters",
        name: "Paneer Tikka",
        description: "Marinated cottage cheese grilled in tandoor",
        price: 199,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 15,
        customizations: [],
      },
      {
        id: "item_masala_chai",
        categoryId: "cat_beverages",
        name: "Masala Chai",
        description: "Traditional Indian spiced tea",
        price: 49,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 5,
        customizations: [],
      },
    ],
  },
  {
    id: "rest_pizza_paradise",
    name: "Pizza Paradise",
    description: "Wood-fired pizzas and Italian classics.",
    cuisineTypes: ["Italian", "Pizza", "Pasta"],
    tags: ["pizza", "pasta", "italian", "wood-fired"],
    averageRating: 4.3,
    totalRatings: 95,
    totalOrders: 870,
    deliveryFee: 40,
    freeDeliveryAbove: 600,
    preparationTimeMinutes: 30,
    minimumOrderAmount: 200,
    priceLevel: 2,
    isActive: true,
    isOpen: true,
    isFeatured: true,
    address: {
      addressLine1: "456 MG Road, Gurugram",
      city: "Gurugram",
      state: "Haryana",
      location: { latitude: 28.4595, longitude: 77.0266 },
    },
    operatingHours: [
      { day: "Monday", openTime: "11:00", closeTime: "23:30", isClosed: false },
      { day: "Tuesday", openTime: "11:00", closeTime: "23:30", isClosed: false },
      { day: "Wednesday", openTime: "11:00", closeTime: "23:30", isClosed: false },
      { day: "Thursday", openTime: "11:00", closeTime: "23:30", isClosed: false },
      { day: "Friday", openTime: "11:00", closeTime: "23:30", isClosed: false },
      { day: "Saturday", openTime: "11:00", closeTime: "00:00", isClosed: false },
      { day: "Sunday", openTime: "11:00", closeTime: "00:00", isClosed: false },
    ],
    phone: "+91-9876543211",
    imageUrl: "",
    coverImageUrl: "",
    categories: [
      { id: "cat_pizzas", name: "Pizzas", sortOrder: 0 },
      { id: "cat_pasta", name: "Pasta", sortOrder: 1 },
      { id: "cat_sides", name: "Sides", sortOrder: 2 },
    ],
    menuItems: [
      {
        id: "item_margherita",
        categoryId: "cat_pizzas",
        name: "Margherita Pizza",
        description: "Classic tomato sauce, mozzarella, and fresh basil",
        price: 299,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: true,
        preparationTime: 20,
        customizations: [
          {
            id: "cust_pizza_size",
            name: "Size",
            type: "single",
            required: true,
            options: [
              { id: "opt_medium", name: "Medium (8\")", price: 0 },
              { id: "opt_large", name: "Large (12\")", price: 120 },
            ],
          },
          {
            id: "cust_crust",
            name: "Crust",
            type: "single",
            required: true,
            options: [
              { id: "opt_thin", name: "Thin Crust", price: 0 },
              { id: "opt_thick", name: "Thick Crust", price: 0 },
              { id: "opt_stuffed", name: "Cheese Stuffed", price: 60 },
            ],
          },
        ],
      },
      {
        id: "item_pepperoni",
        categoryId: "cat_pizzas",
        name: "Pepperoni Pizza",
        description: "Loaded with spicy pepperoni and mozzarella",
        price: 399,
        imageUrl: "",
        isAvailable: true,
        isVeg: false,
        isPopular: true,
        preparationTime: 20,
        customizations: [],
      },
      {
        id: "item_pasta_alfredo",
        categoryId: "cat_pasta",
        name: "Penne Alfredo",
        description: "Creamy white sauce pasta with mushrooms",
        price: 249,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 15,
        customizations: [],
      },
      {
        id: "item_garlic_bread",
        categoryId: "cat_sides",
        name: "Garlic Bread (4 pcs)",
        description: "Toasted bread with garlic butter and herbs",
        price: 129,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: true,
        preparationTime: 10,
        customizations: [],
      },
    ],
  },
  {
    id: "rest_south_spice",
    name: "South Spice Kitchen",
    description: "Authentic South Indian dosas, idlis, and more.",
    cuisineTypes: ["South Indian", "Dosa", "Idli"],
    tags: ["dosa", "idli", "south indian", "thali"],
    averageRating: 4.6,
    totalRatings: 210,
    totalOrders: 2100,
    deliveryFee: 25,
    freeDeliveryAbove: 400,
    preparationTimeMinutes: 25,
    minimumOrderAmount: 100,
    priceLevel: 1,
    isActive: true,
    isOpen: true,
    isFeatured: false,
    address: {
      addressLine1: "789 Anna Nagar, Chennai Style",
      city: "Delhi",
      state: "Delhi",
      location: { latitude: 28.6139, longitude: 77.209 },
    },
    operatingHours: [
      { day: "Monday", openTime: "07:00", closeTime: "22:00", isClosed: false },
      { day: "Tuesday", openTime: "07:00", closeTime: "22:00", isClosed: false },
      { day: "Wednesday", openTime: "07:00", closeTime: "22:00", isClosed: false },
      { day: "Thursday", openTime: "07:00", closeTime: "22:00", isClosed: false },
      { day: "Friday", openTime: "07:00", closeTime: "22:00", isClosed: false },
      { day: "Saturday", openTime: "07:00", closeTime: "22:30", isClosed: false },
      { day: "Sunday", openTime: "07:00", closeTime: "22:30", isClosed: false },
    ],
    phone: "+91-9876543212",
    imageUrl: "",
    coverImageUrl: "",
    categories: [
      { id: "cat_dosa", name: "Dosas", sortOrder: 0 },
      { id: "cat_idli", name: "Idli & Vada", sortOrder: 1 },
      { id: "cat_meals", name: "Meals", sortOrder: 2 },
    ],
    menuItems: [
      {
        id: "item_masala_dosa",
        categoryId: "cat_dosa",
        name: "Masala Dosa",
        description: "Crispy rice crepe filled with spiced potato",
        price: 120,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: true,
        preparationTime: 12,
        customizations: [],
      },
      {
        id: "item_rava_dosa",
        categoryId: "cat_dosa",
        name: "Rava Dosa",
        description: "Crispy semolina crepe with onions and green chillies",
        price: 130,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 15,
        customizations: [],
      },
      {
        id: "item_idli_sambar",
        categoryId: "cat_idli",
        name: "Idli Sambar (4 pcs)",
        description: "Steamed rice cakes with lentil soup and chutneys",
        price: 89,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: true,
        preparationTime: 10,
        customizations: [],
      },
      {
        id: "item_medu_vada",
        categoryId: "cat_idli",
        name: "Medu Vada (3 pcs)",
        description: "Crispy lentil doughnuts with sambar and chutney",
        price: 79,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: false,
        preparationTime: 10,
        customizations: [],
      },
      {
        id: "item_south_thali",
        categoryId: "cat_meals",
        name: "South Indian Thali",
        description: "Complete meal with rice, sambar, rasam, poriyal, and more",
        price: 199,
        imageUrl: "",
        isAvailable: true,
        isVeg: true,
        isPopular: true,
        preparationTime: 20,
        customizations: [],
      },
    ],
  },
];

// ─── App Config ──────────────────────────────────────────────────────────────

const APP_CONFIG = {
  serviceFeePercent: 5.0,
  deliveryFee: 40.0,
  taxPercent: 5.0,
  maxDeliveryRadiusKm: 15.0,
  minOrderAmount: 100.0,
  supportEmail: "support@tuishfood.com",
  supportPhone: "+91-1234567890",
  maintenanceMode: false,
  forceUpdateVersion: "1.0.0",
  updatedAt: FieldValue.serverTimestamp(),
};

// ─── Seed Functions ──────────────────────────────────────────────────────────

async function createOrGetUser({ email, password, displayName, role }) {
  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log(`  ✓ User exists: ${email} (${user.uid})`);
  } catch {
    user = await auth.createUser({ email, password, displayName });
    console.log(`  + Created user: ${email} (${user.uid})`);
  }

  // Set custom claims for role
  await auth.setCustomUserClaims(user.uid, { role });
  console.log(`  ✓ Set role: ${role}`);

  // Save to Firestore
  await db
    .collection("users")
    .doc(user.uid)
    .set(
      {
        uid: user.uid,
        email,
        displayName,
        role,
        isActive: true,
        isBanned: false,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

  return user;
}

async function seedRestaurants() {
  for (const restaurant of RESTAURANTS) {
    const { categories, menuItems, id, ...restData } = restaurant;

    // Convert address.location to GeoPoint
    if (restData.address && restData.address.location) {
      const { latitude, longitude } = restData.address.location;
      restData.address = {
        ...restData.address,
        location: new GeoPoint(latitude, longitude),
      };
    }

    // Write restaurant document
    await db
      .collection("restaurants")
      .doc(id)
      .set(
        {
          ...restData,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    console.log(`  + Restaurant: ${restData.name}`);

    // Write categories as subcollection
    for (const category of categories) {
      await db
        .collection("restaurants")
        .doc(id)
        .collection("menuCategories")
        .doc(category.id)
        .set(category, { merge: true });
    }
    console.log(`    + ${categories.length} categories`);

    // Write menu items as subcollection
    for (const item of menuItems) {
      await db
        .collection("restaurants")
        .doc(id)
        .collection("menuItems")
        .doc(item.id)
        .set(
          {
            ...item,
            createdAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );
    }
    console.log(`    + ${menuItems.length} menu items`);
  }
}

async function seedAppConfig() {
  await db.collection("app_config").doc("settings").set(APP_CONFIG, { merge: true });
  console.log("  + App config saved");
}

// ─── Main ────────────────────────────────────────────────────────────────────

async function main() {
  console.log("\n🍽️  Tuish Food - Seeding Firebase\n");

  console.log("1. Creating users...");
  const createdUsers = {};
  for (const userData of TEST_USERS) {
    const user = await createOrGetUser(userData);
    createdUsers[userData.role] = user.uid;
  }

  console.log("\n2. Seeding restaurants...");
  await seedRestaurants();

  // Assign the first restaurant to the restaurant owner
  if (createdUsers["restaurantOwner"]) {
    const ownerUid = createdUsers["restaurantOwner"];
    await db.collection("restaurants").doc("rest_biryani_house").update({
      ownerUid,
    });
    console.log(`  ✓ Assigned rest_biryani_house to owner ${ownerUid}`);
  }

  console.log("\n3. Seeding app config...");
  await seedAppConfig();

  console.log("\n✅ Seed complete!\n");
  console.log("Test accounts:");
  console.log("  Admin:    admin@tuishfood.com    / Admin@123");
  console.log("  Customer: customer@tuishfood.com / Customer@123");
  console.log("  Driver:   driver@tuishfood.com   / Driver@123");
  console.log("  Owner:    owner@tuishfood.com    / Owner@123\n");
}

main().catch((err) => {
  console.error("Seed failed:", err);
  process.exit(1);
});
