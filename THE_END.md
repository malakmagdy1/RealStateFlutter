# Real Estate API - Complete Documentation

**Base URL:** `https://aqar.bdcbiz.com/api`

**Last Updated:** December 2024

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Companies](#2-companies)
3. [Compounds](#3-compounds)
4. [Units](#4-units)
5. [Search & Filter](#5-search--filter)
6. [Favorites](#6-favorites)
7. [User Profile](#7-user-profile)
8. [Devices](#8-devices)
9. [FCM & Notifications](#9-fcm--notifications)
10. [History](#10-history)
11. [Notes](#11-notes)
12. [Subscriptions](#12-subscriptions)
13. [Unit Updates](#13-unit-updates)
14. [Sales/Offers](#14-salesoffers)
15. [Screen Data Mapping](#15-screen-data-mapping)

---

## Common Headers

### Public Endpoints (No Auth Required)
```
Content-Type: application/json
Accept: application/json
```

### Protected Endpoints (Auth Required)
```
Content-Type: application/json
Accept: application/json
Authorization: Bearer {token}
```

---

## 1. Authentication

### 1.1 Register
**POST** `/register`

**Auth:** None

**Body:**
```json
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "buyer",
    "phone": "+201234567890"
}
```

**Response:**
```json
{
    "success": true,
    "message": "User registered successfully. Please check your email for the verification code.",
    "message_ar": "تم التسجيل بنجاح. يرجى التحقق من بريدك الإلكتروني للحصول على رمز التحقق.",
    "data": {
        "user": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "role": "buyer",
            "phone": "+201234567890",
            "is_verified": false,
            "locale": null,
            "tutorial_seen": false
        },
        "token": "1|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "verification": {
            "email_sent": true,
            "expires_in_minutes": 15
        }
    }
}
```

---

### 1.2 Login (Manual)
**POST** `/login`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "password": "password123",
    "login_method": "manual",
    "device_id": "unique-device-id",
    "device_name": "iPhone 14 Pro",
    "device_type": "ios",
    "os_version": "16.0",
    "app_version": "1.0.0"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Login successful",
    "data": {
        "user": {
            "id": 1,
            "name": "John Doe",
            "email": "john@example.com",
            "role": "buyer",
            "phone": "+201234567890",
            "is_verified": true,
            "locale": "en",
            "tutorial_seen": false,
            "subscription_type": "free",
            "device_limit": 1
        },
        "token": "2|xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "device": {
            "id": 1,
            "device_id": "unique-device-id",
            "device_name": "iPhone 14 Pro"
        },
        "device_info": {
            "is_new_device": true,
            "device_limit": 1,
            "devices_used": 1,
            "remaining_slots": 0,
            "subscription_type": "free"
        }
    }
}
```

---

### 1.3 Login (Google)
**POST** `/login`

**Auth:** None

**Body:**
```json
{
    "login_method": "google",
    "id_token": "google-oauth-id-token",
    "email": "john@gmail.com",
    "name": "John Doe",
    "device_id": "unique-device-id"
}
```

---

### 1.4 Login (Apple)
**POST** `/login`

**Auth:** None

**Body:**
```json
{
    "login_method": "apple",
    "apple_id": "apple-user-id",
    "identity_token": "apple-identity-token",
    "authorization_code": "apple-auth-code",
    "email": "john@privaterelay.appleid.com",
    "name": "John Doe",
    "device_id": "unique-device-id"
}
```

---

### 1.5 Verify Email
**POST** `/verify-email`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "code": "123456"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Email verified successfully",
    "message_ar": "تم التحقق من البريد الإلكتروني بنجاح",
    "data": {
        "user": { ... }
    }
}
```

---

### 1.6 Resend Verification Code
**POST** `/resend-verification-code`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com"
}
```

---

### 1.7 Forgot Password
**POST** `/forgot-password`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com"
}
```

---

### 1.8 Verify Reset Code
**POST** `/verify-reset-code`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "code": "123456"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Reset code verified successfully",
    "data": {
        "reset_token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "email": "john@example.com"
    }
}
```

---

### 1.9 Reset Password
**POST** `/reset-password`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "reset_token": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
}
```

---

### 1.10 Logout
**POST** `/logout`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "message": "Logged out successfully"
}
```

---

### 1.11 Delete Account
**DELETE** `/delete-account`

**Auth:** Required

**Body (optional):**
```json
{
    "reason": "No longer need the app"
}
```

---

### 1.12 Mark Tutorial Seen
**POST** `/tutorial/mark-seen`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "message": "Tutorial marked as seen",
    "data": {
        "tutorial_seen": true
    }
}
```

---

## 2. Companies

### 2.1 List All Companies
**GET** `/companies`

**Auth:** None

**Response:**
```json
{
    "success": true,
    "count": 25,
    "data": [
        {
            "id": 1,
            "name": "Palm Hills",
            "name_en": "Palm Hills",
            "name_ar": "بالم هيلز",
            "logo": "https://aqar.bdcbiz.com/storage/companies/logo.png",
            "email": "info@palmhills.com",
            "number_of_compounds": 15,
            "number_of_available_units": 500,
            "compounds": [
                {
                    "id": 1,
                    "name": "Palm Hills New Cairo",
                    "project": "Palm Hills New Cairo",
                    "project_en": "Palm Hills New Cairo",
                    "project_ar": "بالم هيلز القاهرة الجديدة",
                    "location": "New Cairo",
                    "location_en": "New Cairo",
                    "location_ar": "القاهرة الجديدة",
                    "status": "active",
                    "completion_progress": 80,
                    "images": ["https://..."]
                }
            ]
        }
    ]
}
```

---

### 2.2 Get Company Details
**GET** `/companies/{id}`

**Auth:** None

**Response:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "Palm Hills",
        "name_en": "Palm Hills",
        "name_ar": "بالم هيلز",
        "logo": "https://aqar.bdcbiz.com/storage/companies/logo.png",
        "email": "info@palmhills.com",
        "number_of_compounds": 15,
        "number_of_available_units": 500,
        "compounds": [
            {
                "id": 1,
                "name": "Palm Hills New Cairo",
                "project": "Palm Hills New Cairo",
                "project_en": "Palm Hills New Cairo",
                "project_ar": "بالم هيلز القاهرة الجديدة",
                "location": "New Cairo",
                "location_en": "New Cairo",
                "location_ar": "القاهرة الجديدة",
                "status": "active",
                "completion_progress": 80,
                "total_units": 100,
                "sold_units": 50,
                "available_units": 50,
                "images": ["https://..."],
                "units": [
                    {
                        "id": 1,
                        "unit_code": "PH-001",
                        "unit_name": "Villa A1",
                        "unit_type": "Villa",
                        "usage_type": "Residential",
                        "status": "available",
                        "number_of_beds": 4,
                        "bathrooms": 3,
                        "floor_number": 0,
                        "built_up_area": 350,
                        "total_area": 500,
                        "land_area": 600,
                        "garden_area": 100,
                        "roof_area": 0,
                        "normal_price": 15000000,
                        "total_pricing": 15000000,
                        "cash_price": 14000000,
                        "price_per_meter": 42857,
                        "down_payment": 3000000,
                        "monthly_installment": 150000,
                        "over_years": 8,
                        "finishing_type": "Finished",
                        "delivery_date": "2025-06-01",
                        "is_sold": false,
                        "available": true,
                        "images": ["https://..."],
                        "payment_plans": [
                            {
                                "id": 1,
                                "plan_name": "8 Years Plan",
                                "price": 15000000,
                                "duration_years": 8,
                                "total_area": 350,
                                "finishing_type": "Finished",
                                "delivery_date": "2025-06-01",
                                "down_payment_percentage": 20,
                                "down_payment_amount": 3000000,
                                "monthly_installment": 150000,
                                "number_of_installments": 96,
                                "installment_details": "Equal monthly installments",
                                "description": "Standard 8 year payment plan"
                            }
                        ]
                    }
                ]
            }
        ],
        "users": [
            {
                "id": 5,
                "name": "Ahmed Sales",
                "email": "ahmed@palmhills.com",
                "role": "sales",
                "phone": "+201234567890"
            }
        ]
    }
}
```

---

## 3. Compounds

### 3.1 List All Compounds
**GET** `/compounds`

**Auth:** None

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number (default: 1) |
| limit | int | Items per page (default: 20) |
| company_id | int | Filter by company ID |
| location | string | Filter by location |
| is_sold | bool | Filter by sold status |

**Example:** `/compounds?page=1&limit=20&location=New Cairo`

**Response:**
```json
{
    "success": true,
    "count": 20,
    "total": 150,
    "page": 1,
    "limit": 20,
    "total_pages": 8,
    "data": [
        {
            "id": 1372,
            "project": "Palm Hills New Cairo",
            "project_en": "Palm Hills New Cairo",
            "project_ar": "بالم هيلز القاهرة الجديدة",
            "location": "New Cairo",
            "location_en": "New Cairo",
            "location_ar": "القاهرة الجديدة",
            "status": "active",
            "completion_progress": 80,
            "images": ["https://..."],
            "company_id": 1,
            "company_name": "Palm Hills",
            "company_logo": "logo.png",
            "company_logo_url": "https://aqar.bdcbiz.com/storage/companies/logo.png",
            "company": {
                "id": 1,
                "name": "Palm Hills",
                "logo": "logo.png",
                "logo_url": "https://..."
            },
            "sales_person": {
                "id": 5,
                "name": "Ahmed Sales",
                "email": "ahmed@palmhills.com",
                "phone": "+201234567890",
                "image": null
            },
            "current_sale": {
                "id": 1,
                "sale_name": "Summer Sale",
                "description": "20% discount on all units",
                "discount_percentage": 20,
                "start_date": "2024-06-01",
                "end_date": "2024-08-31",
                "is_active": true
            },
            "total_units": 100,
            "sold_units": 50,
            "available_units": 50,
            "units": [
                {
                    "id": 1,
                    "unit_code": "PH-001",
                    "unit_name": "Villa A1",
                    "unit_type": "Villa",
                    "usage_type": "Residential",
                    "status": "available",
                    "number_of_beds": 4,
                    "bathrooms": 3,
                    "floor_number": 0,
                    "built_up_area": 350,
                    "total_area": 500,
                    "land_area": 600,
                    "garden_area": 100,
                    "roof_area": 0,
                    "normal_price": 15000000,
                    "total_pricing": 15000000,
                    "cash_price": 14000000,
                    "price_per_meter": 42857,
                    "down_payment": 3000000,
                    "monthly_installment": 150000,
                    "over_years": 8,
                    "finishing_type": "Finished",
                    "delivery_date": "2025-06-01",
                    "is_sold": false,
                    "available": true,
                    "images": ["https://..."],
                    "payment_plans": [...]
                }
            ]
        }
    ]
}
```

---

### 3.2 Get Compound Details
**GET** `/compounds/{id}`

**Auth:** None

**Response:** Same structure as list item but single object in `data`

---

## 4. Units

### 4.1 List All Units
**GET** `/units`

**Auth:** Required

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number |
| limit | int | Items per page |
| compound_id | int | Filter by compound |
| company_id | int | Filter by company |
| unit_type | string | Filter by type (Villa, Apartment, etc.) |
| available | bool | Filter available only |
| is_sold | bool | Filter sold only |
| status | string | Filter by status |
| number_of_beds | int | Filter by bedrooms |
| min_price | float | Minimum price |
| max_price | float | Maximum price |
| search | string | Search in unit code/name |

**Response:**
```json
{
    "success": true,
    "count": 20,
    "total": 500,
    "page": 1,
    "limit": 20,
    "total_pages": 25,
    "data": [
        {
            "id": 1,
            "compound_id": 1372,
            "compound_name": "Palm Hills New Cairo",
            "compound_location": "New Cairo",
            "company_id": 1,
            "company_name": "Palm Hills",
            "company_logo": "https://...",
            "unit_name": "Villa A1",
            "unit_code": "PH-001",
            "code": "PH-001",
            "unit_type": "Villa",
            "usage_type": "Residential",
            "status": "available",
            "number_of_beds": 4,
            "floor_number": 0,
            "original_price": 15000000,
            "normal_price": 12000000,
            "discounted_price": 12000000,
            "discount_percentage": 20,
            "has_active_sale": true,
            "total_pricing": 15000000,
            "total_area": 500,
            "built_up_area": 350,
            "land_area": 600,
            "payment_plan": {
                "down_payment": 3000000,
                "monthly_installment": 150000,
                "over_years": 8
            },
            "down_payment": 3000000,
            "monthly_installment": 150000,
            "over_years": 8,
            "finishing_type": "Finished",
            "total_finish_pricing": null,
            "unit_total_with_finish_price": null,
            "delivery_date": "2025-06-01",
            "planned_delivery_date": "2025-06-01",
            "actual_delivery_date": null,
            "delivered_at": null,
            "completion_progress": 80,
            "available": true,
            "is_sold": false,
            "images": ["https://..."],
            "created_at": "2024-01-15T10:30:00.000000Z",
            "updated_at": "2024-06-01T14:20:00.000000Z",
            "unit_name_localized": "Villa A1",
            "unit_type_localized": "Villa",
            "usage_type_localized": "Residential",
            "status_localized": "available",
            "compound": {
                "id": 1372,
                "name": "Palm Hills New Cairo",
                "project": "Palm Hills New Cairo",
                "location": "New Cairo",
                "status": "active",
                "completion_progress": 80,
                "images": ["https://..."]
            },
            "company": {
                "id": 1,
                "name": "Palm Hills",
                "logo": "https://...",
                "email": "info@palmhills.com"
            },
            "sale": {
                "id": 1,
                "sale_name": "Summer Sale",
                "description": "20% discount",
                "discount_percentage": 20,
                "start_date": "2024-06-01",
                "end_date": "2024-08-31",
                "is_active": true
            },
            "payment_plans": [
                {
                    "id": 1,
                    "plan_name": "8 Years Plan",
                    "price": 15000000,
                    "duration_years": 8,
                    "total_area": 350,
                    "finishing_type": "Finished",
                    "delivery_date": "2025-06-01",
                    "down_payment_percentage": 20,
                    "down_payment_amount": 3000000,
                    "monthly_installment": 150000,
                    "number_of_installments": 96,
                    "installment_details": "Equal monthly",
                    "description": "Standard plan"
                }
            ],
            "change_type": "new",
            "changed_fields": []
        }
    ]
}
```

---

### 4.2 Get Unit Details
**GET** `/units/{id}`

**Auth:** Required

**Response:** Same structure as list item but single object in `data`

---

### 4.3 Filter Units
**POST** `/filter-units` or **GET** `/filter-units`

**Auth:** Required

**Body/Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| page | int | Page number |
| limit | int | Items per page |
| usage_type | string | Residential, Commercial |
| unit_type | string | Villa, Apartment, etc. |
| status | string | available, sold |
| unit_name | string | Search by name |
| building_name | string | Building name |
| stage_number | int | Stage number |
| number_of_beds | int | Number of bedrooms |
| floor_number | int | Floor number |
| compound_id | int | Compound ID |
| company_id | int | Company ID |
| location | string | Location |
| available | bool | Available units |
| is_sold | bool | Sold units |
| min_price | float | Minimum price |
| max_price | float | Maximum price |
| min_total_pricing | float | Min total pricing |
| max_total_pricing | float | Max total pricing |
| min_garden_area | float | Min garden area |
| max_garden_area | float | Max garden area |
| min_roof_area | float | Min roof area |
| max_roof_area | float | Max roof area |

**Response:**
```json
{
    "success": true,
    "total_units": 150,
    "page": 1,
    "limit": 20,
    "total_pages": 8,
    "filters_applied": ["company_id", "min_price", "number_of_beds"],
    "units": [...],
    "subscription": {
        "plan_name": "Premium",
        "searches_used": 5,
        "search_limit": 100,
        "remaining_searches": 95,
        "expires_at": "2025-01-15 23:59:59"
    }
}
```

---

## 5. Search & Filter

### 5.1 Unified Search and Filter (PUBLIC)
**GET** `/search-and-filter`

**Auth:** None (but authenticated users get subscription tracking)

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| search | string | Search keyword |
| page | int | Page number |
| limit | int | Items per page |
| company | string | Company name |
| company_id | int | Company ID |
| compound_id | int | Compound ID |
| location | string | Location |
| property_type | string | Villa,Apartment (comma-separated) |
| property_types | string | Same as property_type |
| unit_type | string | Unit type |
| usage_type | string | Usage type |
| number_of_beds | string | 1,2,3 (comma-separated) |
| bedroom | string | Same as number_of_beds |
| bedrooms | string | Same as number_of_beds |
| min_price | float | Minimum price |
| max_price | float | Maximum price |
| min_built_up_area | float | Min built-up area |
| max_built_up_area | float | Max built-up area |
| min_land_area | float | Min land area |
| max_land_area | float | Max land area |
| min_garden_area | float | Min garden area |
| max_garden_area | float | Max garden area |
| finishing_type | string | Finished, Semi-Finished |
| finishing | string | Same as finishing_type |
| floor_number | int | Floor number |
| is_sold | bool | Sold status |
| available | bool | Available status |
| has_active_sale | bool | Has active sale |
| has_club | bool | Has club amenity |
| has_roof | bool | Has roof |
| has_garden | bool | Has garden |
| payment_duration | string | cash_only, 5, 7, 10 |
| min_monthly_payment | float | Min monthly payment |
| max_monthly_payment | float | Max monthly payment |
| delivered_from | date | Delivery date from (YYYY-MM-DD) |
| delivered_to | date | Delivery date to |
| delivery_status | string | all, delivered, not_delivered |
| planned_delivery_from | date | Planned delivery from |
| planned_delivery_to | date | Planned delivery to |
| sort_by | string | newest, price_low_to_high, price_high_to_low, oldest, area_asc, area_desc |

**Example:**
```
/search-and-filter?search=palm&location=New Cairo&property_type=Villa,Apartment&number_of_beds=3,4&min_price=5000000&max_price=20000000&finishing_type=Finished&sort_by=price_low_to_high
```

**Response:**
```json
{
    "success": true,
    "message": null,
    "message_ar": null,
    "has_results": true,
    "search_query": "palm",
    "total_results": 75,
    "total_companies": 1,
    "total_compounds": 4,
    "total_units": 70,
    "page": 1,
    "limit": 20,
    "total_pages": 4,
    "sort_by": "price_low_to_high",
    "filters_applied": ["location", "property_type", "number_of_beds", "min_price", "max_price", "finishing_type"],
    "available_filters": {
        "company": "Company name or ID",
        "location": "Location/area name",
        "min_price": "Minimum price",
        "max_price": "Maximum price",
        "property_type": "Villa, Apartment, Studio, Duplex, Penthouse",
        "bedrooms": "Number of bedrooms",
        "finishing_type": "Finished, Semi-Finished",
        "delivered_from": "Delivery date from (YYYY-MM-DD)",
        "delivered_to": "Delivery date to (YYYY-MM-DD)",
        "delivery_status": "all, delivered, not_delivered",
        "has_club": "true/false",
        "has_roof": "true/false",
        "has_garden": "true/false",
        "payment_duration": "all, cash_only, 5, 7, 10 (years)",
        "min_monthly_payment": "Minimum monthly installment",
        "max_monthly_payment": "Maximum monthly installment",
        "sort_by": "newest, price_low_to_high, price_high_to_low, oldest"
    },
    "companies": [
        {
            "type": "company",
            "id": 1,
            "name": "Palm Hills",
            "email": "info@palmhills.com",
            "logo": "https://...",
            "number_of_compounds": 15,
            "number_of_available_units": 500,
            "compounds_count": 15,
            "created_at": "2024-01-01T00:00:00.000000Z"
        }
    ],
    "compounds": [
        {
            "type": "compound",
            "id": 1372,
            "name": "Palm Hills New Cairo",
            "project": "Palm Hills New Cairo",
            "location": "New Cairo",
            "status": "active",
            "completion_progress": 80,
            "units_count": 100,
            "available_units_count": 50,
            "has_active_sale": true,
            "sale": {
                "id": 1,
                "sale_name": "Summer Sale",
                "discount_percentage": 20
            },
            "company": {
                "id": 1,
                "name": "Palm Hills",
                "logo": "https://..."
            },
            "images": ["https://..."],
            "created_at": "2024-01-01T00:00:00.000000Z"
        }
    ],
    "units": [
        {
            "id": 1,
            "compound_id": 1372,
            "compound_name": "Palm Hills New Cairo",
            "compound_location": "New Cairo",
            "company_id": 1,
            "company_name": "Palm Hills",
            "company_logo": "https://...",
            "unit_name": "Villa A1",
            "unit_code": "PH-001",
            "unit_type": "Villa",
            "usage_type": "Residential",
            "status": "available",
            "number_of_beds": 4,
            "floor_number": 0,
            "original_price": 15000000,
            "normal_price": 12000000,
            "discounted_price": 12000000,
            "discount_percentage": 20,
            "has_active_sale": true,
            "built_up_area": 350,
            "land_area": 600,
            "garden_area": 100,
            "roof_area": 0,
            "total_area": 500,
            "down_payment": 3000000,
            "monthly_installment": 150000,
            "over_years": 8,
            "finishing_type": "Finished",
            "available": true,
            "is_sold": false,
            "images": ["https://..."],
            "delivery_date": "2025-06-01",
            "compound": {...},
            "company": {...},
            "sale": {...},
            "payment_plans": [...]
        }
    ],
    "subscription": {
        "plan_name": "Premium",
        "searches_used": 5,
        "search_limit": 100,
        "remaining_searches": 95,
        "expires_at": "2025-01-15 23:59:59"
    }
}
```

---

### 5.2 Search in Compound (PUBLIC)
**GET** `/units/search-in-compound`

**Auth:** None

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| compound_id | int | Required - Compound ID |
| search | string | Search keyword |
| unit_type | string | Filter by unit type |
| number_of_beds | int | Filter by bedrooms |
| min_price | float | Minimum price |
| max_price | float | Maximum price |
| is_sold | bool | Sold status |

---

## 6. Favorites

### 6.1 List Favorites
**GET** `/favorites`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "count": 5,
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "unit_id": 1,
            "note": "Nice villa, good price",
            "created_at": "2024-06-01T10:00:00.000000Z",
            "unit": {
                "id": 1,
                "unit_name": "Villa A1",
                "unit_code": "PH-001",
                "normal_price": 12000000,
                "images": ["https://..."],
                "compound": {...},
                "company": {...}
            }
        }
    ]
}
```

---

### 6.2 Add to Favorites
**POST** `/favorites`

**Auth:** Required

**Body:**
```json
{
    "unit_id": 1,
    "note": "Nice villa, good price"
}
```

---

### 6.3 Update Favorite
**PUT** `/favorites`

**Auth:** Required

**Body:**
```json
{
    "unit_id": 1,
    "note": "Updated note"
}
```

---

### 6.4 Remove from Favorites
**DELETE** `/favorites`

**Auth:** Required

**Body:**
```json
{
    "unit_id": 1
}
```

---

### 6.5 Get Favorites with Notes
**GET** `/favorites/notes`

**Auth:** Required

---

## 7. User Profile

### 7.1 Get Profile
**GET** `/profile`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+201234567890",
        "role": "buyer",
        "image": "https://...",
        "locale": "en",
        "is_verified": true,
        "tutorial_seen": true,
        "subscription_type": "premium",
        "device_limit": 6,
        "created_at": "2024-01-01T00:00:00.000000Z"
    }
}
```

---

### 7.2 Update Profile
**PUT** `/profile`

**Auth:** Required

**Body:**
```json
{
    "name": "John Updated",
    "phone": "+201234567899"
}
```

---

### 7.3 Update Name Only
**PUT** `/profile/name`

**Auth:** Required

**Body:**
```json
{
    "name": "New Name"
}
```

---

### 7.4 Update Phone Only
**PUT** `/profile/phone`

**Auth:** Required

**Body:**
```json
{
    "phone": "+201234567899"
}
```

---

### 7.5 Change Password
**POST** `/change-password`

**Auth:** Required

**Body:**
```json
{
    "current_password": "oldpassword",
    "password": "newpassword123",
    "password_confirmation": "newpassword123"
}
```

---

### 7.6 Upload Profile Image
**POST** `/upload-image`

**Auth:** Required

**Body:** Form-data with `image` file

---

## 8. Devices

### 8.1 List Devices
**GET** `/devices`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "device_id": "unique-device-id",
            "device_name": "iPhone 14 Pro",
            "device_type": "ios",
            "os_version": "16.0",
            "app_version": "1.0.0",
            "last_active_at": "2024-06-01T15:30:00.000000Z",
            "ip_address": "192.168.1.1",
            "created_at": "2024-01-01T00:00:00.000000Z"
        }
    ]
}
```

---

### 8.2 Remove Device
**DELETE** `/devices/{deviceId}`

**Auth:** Required

---

### 8.3 Check Device
**POST** `/devices/check`

**Auth:** Required

**Body:**
```json
{
    "device_id": "unique-device-id"
}
```

---

### 8.4 Remote Logout
**POST** `/devices/remote-logout`

**Auth:** Required

**Body:**
```json
{
    "device_id": "device-to-logout"
}
```

---

### 8.5 Get Devices by Email (No Auth)
**POST** `/devices/by-email`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "password": "password123"
}
```

---

### 8.6 Remove Device by Email (No Auth)
**POST** `/devices/remove-by-email`

**Auth:** None

**Body:**
```json
{
    "email": "john@example.com",
    "password": "password123",
    "device_id": "device-to-remove"
}
```

---

## 9. FCM & Notifications

### 9.1 Store FCM Token
**POST** `/fcm-token`

**Auth:** Required

**Body:**
```json
{
    "fcm_token": "firebase-cloud-messaging-token",
    "locale": "en"
}
```

**Response:**
```json
{
    "success": true,
    "message": "FCM token saved successfully",
    "data": {
        "user_id": 1,
        "token_length": 152,
        "locale": "en"
    }
}
```

---

### 9.2 Remove FCM Token
**DELETE** `/fcm-token`

**Auth:** Required

---

### 9.3 Update Locale
**POST** `/update-locale`

**Auth:** Required

**Body:**
```json
{
    "locale": "en"
}
```

**Response:**
```json
{
    "success": true,
    "message": "Locale updated successfully",
    "data": {
        "user_id": 1,
        "locale": "en"
    }
}
```

---

## 10. History

### 10.1 List History
**GET** `/history`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "user_id": 1,
            "type": "unit_view",
            "item_id": 1,
            "item_type": "unit",
            "data": {...},
            "created_at": "2024-06-01T10:00:00.000000Z"
        }
    ]
}
```

---

### 10.2 Add to History
**POST** `/history`

**Auth:** Required

**Body:**
```json
{
    "type": "unit_view",
    "item_id": 1,
    "item_type": "unit"
}
```

---

### 10.3 Delete History Item
**DELETE** `/history/{id}`

**Auth:** Required

---

### 10.4 Clear All History
**DELETE** `/history-clear`

**Auth:** Required

---

### 10.5 Recently Viewed
**GET** `/history/recently-viewed`

**Auth:** Required

---

### 10.6 Search History
**GET** `/history/searches`

**Auth:** Required

---

## 11. Notes

### 11.1 List Notes
**GET** `/notes`

**Auth:** Required

---

### 11.2 Create Note
**POST** `/notes`

**Auth:** Required

**Body:**
```json
{
    "unit_id": 1,
    "title": "My note",
    "content": "Note content here"
}
```

---

### 11.3 Get Note
**GET** `/notes/{id}`

**Auth:** Required

---

### 11.4 Update Note
**PUT** `/notes/{id}`

**Auth:** Required

**Body:**
```json
{
    "title": "Updated title",
    "content": "Updated content"
}
```

---

### 11.5 Delete Note
**DELETE** `/notes/{id}`

**Auth:** Required

---

## 12. Subscriptions

### 12.1 Get Subscription Plans
**GET** `/subscription-plans`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "name": "Free",
            "description": "Basic plan",
            "price": 0,
            "duration_days": null,
            "search_limit": 10,
            "device_limit": 1,
            "features": ["Basic search", "View listings"]
        },
        {
            "id": 2,
            "name": "Premium",
            "description": "Full access",
            "price": 99.99,
            "duration_days": 30,
            "search_limit": 100,
            "device_limit": 6,
            "features": ["Unlimited search", "Priority support", "Multiple devices"]
        }
    ]
}
```

---

### 12.2 Get Current Subscription
**GET** `/subscription/current`

**Auth:** Required

**Response:**
```json
{
    "success": true,
    "data": {
        "id": 1,
        "user_id": 1,
        "subscription_plan_id": 2,
        "status": "active",
        "searches_used": 5,
        "started_at": "2024-06-01T00:00:00.000000Z",
        "expires_at": "2024-07-01T00:00:00.000000Z",
        "plan": {
            "name": "Premium",
            "search_limit": 100,
            "device_limit": 6
        }
    }
}
```

---

### 12.3 Check Subscription Status
**GET** `/subscription/status`

**Auth:** Required

---

### 12.4 Subscribe to Plan
**POST** `/subscription/subscribe`

**Auth:** Required

**Body:**
```json
{
    "plan_id": 2
}
```

---

### 12.5 Cancel Subscription
**POST** `/subscription/cancel`

**Auth:** Required

---

### 12.6 Assign Free Plan
**POST** `/subscription/free-plan`

**Auth:** Required

---

## 13. Unit Updates

### 13.1 Get New Units (PUBLIC)
**GET** `/units/new`

**Auth:** None

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| days | int | Units added in last X days (default: 7) |
| page | int | Page number |
| limit | int | Items per page |

---

### 13.2 Get Updated Units (PUBLIC)
**GET** `/units/updated`

**Auth:** None

---

### 13.3 Get All Changes (PUBLIC)
**GET** `/units/changes`

**Auth:** None

---

### 13.4 Get Changes Summary (PUBLIC)
**GET** `/units/changes/summary`

**Auth:** None

**Response:**
```json
{
    "success": true,
    "data": {
        "new_units_count": 15,
        "updated_units_count": 30,
        "price_changes_count": 10,
        "sold_units_count": 5,
        "last_updated": "2024-06-01T15:30:00.000000Z"
    }
}
```

---

### 13.5 Mark Unit as Seen (PUBLIC)
**POST** `/units/{id}/mark-seen`

**Auth:** None

---

### 13.6 Mark Multiple Units as Seen (PUBLIC)
**POST** `/units/mark-seen/multiple`

**Auth:** None

**Body:**
```json
{
    "unit_ids": [1, 2, 3, 4, 5]
}
```

---

### 13.7 Mark All as Seen (PUBLIC)
**POST** `/units/mark-seen/all`

**Auth:** None

---

## 14. Sales/Offers

### 14.1 List All Sales (PUBLIC)
**GET** `/sales`

**Auth:** None

**Response:**
```json
{
    "success": true,
    "data": [
        {
            "id": 1,
            "sale_name": "Summer Sale 2024",
            "description": "20% discount on all units",
            "discount_percentage": 20,
            "start_date": "2024-06-01",
            "end_date": "2024-08-31",
            "is_active": true,
            "compound": {
                "id": 1372,
                "name": "Palm Hills New Cairo",
                "location": "New Cairo"
            },
            "company": {
                "id": 1,
                "name": "Palm Hills"
            }
        }
    ]
}
```

---

### 14.2 Get Sale Details (PUBLIC)
**GET** `/sales/{id}`

**Auth:** None

---

### 14.3 Get Companies with Sales
**GET** `/companies-with-sales`

**Auth:** Required

---

## 15. Screen Data Mapping

This section shows which API endpoints provide data for each screen in the mobile app.

### 15.1 Company Card

| Field | Source API | Data Path |
|-------|-----------|-----------|
| Company Name | `/companies` | `data[].name` |
| Company Name (EN) | `/companies` | `data[].name_en` |
| Company Name (AR) | `/companies` | `data[].name_ar` |
| Logo | `/companies` | `data[].logo` |
| Number of Compounds | `/companies` | `data[].number_of_compounds` |
| Available Units | `/companies` | `data[].number_of_available_units` |

**APIs Used:**
- `GET /companies` - List view
- `GET /companies/{id}` - Detail view
- `GET /search-and-filter` - Search results (`companies[]`)

---

### 15.2 Compound Card

| Field | Source API | Data Path |
|-------|-----------|-----------|
| Project Name | `/compounds` | `data[].project` |
| Project Name (EN) | `/compounds` | `data[].project_en` |
| Project Name (AR) | `/compounds` | `data[].project_ar` |
| Location | `/compounds` | `data[].location` |
| Location (EN) | `/compounds` | `data[].location_en` |
| Location (AR) | `/compounds` | `data[].location_ar` |
| Status | `/compounds` | `data[].status` |
| Completion Progress | `/compounds` | `data[].completion_progress` |
| Images | `/compounds` | `data[].images[]` |
| Company Name | `/compounds` | `data[].company_name` |
| Company Logo | `/compounds` | `data[].company_logo_url` |
| Total Units | `/compounds` | `data[].total_units` |
| Sold Units | `/compounds` | `data[].sold_units` |
| Available Units | `/compounds` | `data[].available_units` |
| Sales Person | `/compounds` | `data[].sales_person` |
| Active Sale | `/compounds` | `data[].current_sale` |

**APIs Used:**
- `GET /compounds` - List view
- `GET /compounds/{id}` - Detail view
- `GET /companies/{id}` - Company's compounds
- `GET /search-and-filter` - Search results (`compounds[]`)

---

### 15.3 Unit Card

| Field | Source API | Data Path |
|-------|-----------|-----------|
| Unit Name | `/units`, `/search-and-filter` | `unit_name` |
| Unit Code | `/units`, `/search-and-filter` | `unit_code` |
| Unit Type | `/units`, `/search-and-filter` | `unit_type` |
| Usage Type | `/units`, `/search-and-filter` | `usage_type` |
| Status | `/units`, `/search-and-filter` | `status` |
| Number of Beds | `/units`, `/search-and-filter` | `number_of_beds` |
| Floor Number | `/units`, `/search-and-filter` | `floor_number` |
| Built-up Area | `/units`, `/search-and-filter` | `built_up_area` |
| Total Area | `/units`, `/search-and-filter` | `total_area` |
| Land Area | `/units`, `/search-and-filter` | `land_area` |
| Garden Area | `/units`, `/search-and-filter` | `garden_area` |
| Roof Area | `/units`, `/search-and-filter` | `roof_area` |
| Original Price | `/units`, `/search-and-filter` | `original_price` |
| Current Price | `/units`, `/search-and-filter` | `normal_price` |
| Discounted Price | `/units`, `/search-and-filter` | `discounted_price` |
| Discount % | `/units`, `/search-and-filter` | `discount_percentage` |
| Has Active Sale | `/units`, `/search-and-filter` | `has_active_sale` |
| Down Payment | `/units`, `/search-and-filter` | `down_payment` |
| Monthly Installment | `/units`, `/search-and-filter` | `monthly_installment` |
| Payment Years | `/units`, `/search-and-filter` | `over_years` |
| Finishing Type | `/units`, `/search-and-filter` | `finishing_type` |
| Delivery Date | `/units`, `/search-and-filter` | `delivery_date` |
| Is Sold | `/units`, `/search-and-filter` | `is_sold` |
| Available | `/units`, `/search-and-filter` | `available` |
| Images | `/units`, `/search-and-filter` | `images[]` |
| Compound Info | `/units`, `/search-and-filter` | `compound` |
| Company Info | `/units`, `/search-and-filter` | `company` |
| Sale Info | `/units`, `/search-and-filter` | `sale` |
| Payment Plans | `/units`, `/search-and-filter` | `payment_plans[]` |
| Change Type | `/units` | `change_type` |
| Changed Fields | `/units` | `changed_fields[]` |

**APIs Used:**
- `GET /units` - List view
- `GET /units/{id}` - Detail view
- `GET /filter-units` - Filtered list
- `GET /search-and-filter` - Search results (`units[]`)
- `GET /compounds/{id}` - Compound's units (`data.units[]`)
- `GET /companies/{id}` - Company's units (through compounds)
- `GET /favorites` - Favorite units
- `GET /history/recently-viewed` - Recently viewed

---

### 15.4 Payment Plan Card

| Field | Source API | Data Path |
|-------|-----------|-----------|
| Plan Name | `/units/{id}` | `payment_plans[].plan_name` |
| Price | `/units/{id}` | `payment_plans[].price` |
| Duration (Years) | `/units/{id}` | `payment_plans[].duration_years` |
| Total Area | `/units/{id}` | `payment_plans[].total_area` |
| Finishing Type | `/units/{id}` | `payment_plans[].finishing_type` |
| Delivery Date | `/units/{id}` | `payment_plans[].delivery_date` |
| Down Payment % | `/units/{id}` | `payment_plans[].down_payment_percentage` |
| Down Payment Amount | `/units/{id}` | `payment_plans[].down_payment_amount` |
| Monthly Installment | `/units/{id}` | `payment_plans[].monthly_installment` |
| Number of Installments | `/units/{id}` | `payment_plans[].number_of_installments` |
| Installment Details | `/units/{id}` | `payment_plans[].installment_details` |
| Description | `/units/{id}` | `payment_plans[].description` |

**APIs Used:**
- `GET /units/{id}` - Unit detail
- `GET /compounds/{id}` - Compound units with payment plans
- `GET /companies/{id}` - Company units with payment plans
- `GET /search-and-filter` - Search results with payment plans

---

### 15.5 Sale/Offer Card

| Field | Source API | Data Path |
|-------|-----------|-----------|
| Sale Name | `/sales` | `data[].sale_name` |
| Description | `/sales` | `data[].description` |
| Discount % | `/sales` | `data[].discount_percentage` |
| Start Date | `/sales` | `data[].start_date` |
| End Date | `/sales` | `data[].end_date` |
| Is Active | `/sales` | `data[].is_active` |
| Compound | `/sales` | `data[].compound` |
| Company | `/sales` | `data[].company` |

**APIs Used:**
- `GET /sales` - List all sales
- `GET /sales/{id}` - Sale detail
- `GET /companies-with-sales` - Companies with active sales

---

### 15.6 Screen-to-API Mapping Table

| Screen | Primary API | Secondary APIs |
|--------|-------------|----------------|
| **Home Screen** | `GET /search-and-filter` | `GET /units/changes/summary`, `GET /sales` |
| **Companies List** | `GET /companies` | - |
| **Company Detail** | `GET /companies/{id}` | - |
| **Compounds List** | `GET /compounds` | - |
| **Compound Detail** | `GET /compounds/{id}` | - |
| **Units List** | `GET /units` | `GET /filter-units` |
| **Unit Detail** | `GET /units/{id}` | - |
| **Search Screen** | `GET /search-and-filter` | - |
| **Filter Screen** | `GET /filter-units` | - |
| **Favorites** | `GET /favorites` | `GET /favorites/notes` |
| **History** | `GET /history` | `GET /history/recently-viewed` |
| **Profile** | `GET /profile` | `GET /subscription/current` |
| **Settings** | `GET /profile` | `GET /devices` |
| **Devices** | `GET /devices` | - |
| **Subscription** | `GET /subscription-plans` | `GET /subscription/current`, `GET /subscription/status` |
| **Sales/Offers** | `GET /sales` | `GET /companies-with-sales` |
| **New Units** | `GET /units/new` | - |
| **Updated Units** | `GET /units/updated` | `GET /units/changes` |
| **Login** | `POST /login` | - |
| **Register** | `POST /register` | - |
| **Verify Email** | `POST /verify-email` | `POST /resend-verification-code` |
| **Forgot Password** | `POST /forgot-password` | `POST /verify-reset-code`, `POST /reset-password` |
| **Notes** | `GET /notes` | `POST /notes`, `PUT /notes/{id}`, `DELETE /notes/{id}` |

---

### 15.7 Data Flow Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP SCREENS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Company    │  │   Compound   │  │    Unit      │          │
│  │    Card      │  │    Card      │  │    Card      │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                 │                 │                   │
│         ▼                 ▼                 ▼                   │
│  ┌──────────────────────────────────────────────────┐          │
│  │              GET /search-and-filter               │          │
│  │  Returns: companies[], compounds[], units[]       │          │
│  └──────────────────────────────────────────────────┘          │
│                                                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │GET /companies│ │GET /compounds│ │GET /units   │              │
│  │GET /companies/{id}│ │GET /compounds/{id}│ │GET /units/{id}│  │
│  └────────────┘  └────────────┘  └────────────┘                │
│                                                                  │
│  ┌────────────────────────────────────────────────┐            │
│  │              Supporting APIs                     │            │
│  │  - GET /favorites                               │            │
│  │  - GET /history                                 │            │
│  │  - GET /sales                                   │            │
│  │  - GET /units/new                               │            │
│  │  - GET /units/updated                           │            │
│  │  - GET /subscription/current                    │            │
│  └────────────────────────────────────────────────┘            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Error Responses

All endpoints may return these error formats:

### Validation Error (422)
```json
{
    "success": false,
    "message": "Validation error",
    "errors": {
        "email": ["The email field is required."],
        "password": ["The password must be at least 8 characters."]
    }
}
```

### Unauthorized (401)
```json
{
    "success": false,
    "message": "Unauthenticated."
}
```

### Not Found (404)
```json
{
    "success": false,
    "error": "Unit not found"
}
```

### Server Error (500)
```json
{
    "success": false,
    "error": "Database error",
    "message": "Error details..."
}
```

### Device Limit Reached (403)
```json
{
    "success": false,
    "message": "Device limit reached. You have reached the maximum number of devices (1) for your free subscription.",
    "message_ar": "تم الوصول إلى الحد الأقصى للأجهزة...",
    "data": {
        "device_limit": 1,
        "devices_used": 1,
        "subscription_type": "free",
        "devices": [...]
    }
}
```

---

## Localization

The API supports bilingual responses:
- `message` - English message
- `message_ar` - Arabic message

For localized field names in units/compounds:
- `project` / `project_en` / `project_ar`
- `location` / `location_en` / `location_ar`
- `name` / `name_en` / `name_ar`
- `unit_name_localized`
- `unit_type_localized`
- `usage_type_localized`
- `status_localized`

---

## Rate Limiting

- Public endpoints: 60 requests/minute
- Authenticated endpoints: 120 requests/minute
- Search endpoints: Based on subscription plan

---

## Changelog

### December 2024
- Added TTL=0 for FCM notifications (immediate delivery only)
- Updated `/compounds` list endpoint to return same data as `/compounds/{id}`
- Added `payment_plans` to compound list response
- Added localized fields to all endpoints

---

**END OF DOCUMENTATION**
