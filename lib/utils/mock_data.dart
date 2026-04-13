// ═══════════════════════════════════════════════════════════════════════════
//  MOCK JSON DATA — Real API ga o'xshash to'liq ma'lumotlar
//  Farg'ona viloyati: 14 ta tuman/shahar
// ═══════════════════════════════════════════════════════════════════════════

const String kMockHouseholdsJson = '''
[
  {
    "id": 1, "region_id": 1, "district_id": 1, "created_by_agent_id": 1,
    "official_address": "Farg'ona sh., Mustaqillik ko'chasi, 14-uy",
    "house_number": "14",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Tinchlik MFY",
    "street_name": "Mustaqillik ko'chasi",
    "latitude": 40.3842, "longitude": 71.7825,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-15T08:00:00.000Z", "updated_at": "2024-03-10T12:00:00.000Z",
    "residents": [
      { "id": 1, "household_id": 1, "first_name": "Bobur", "last_name": "Karimov", "phone_primary": "+998901112233", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1980-05-10", "created_at": "2024-01-15T08:00:00.000Z", "updated_at": "2024-01-15T08:00:00.000Z" },
      { "id": 2, "household_id": 1, "first_name": "Dilnoza", "last_name": "Karimova", "phone_primary": "+998901112244", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1983-08-22", "created_at": "2024-01-15T08:00:00.000Z", "updated_at": "2024-01-15T08:00:00.000Z" },
      { "id": 3, "household_id": 1, "first_name": "Sardor", "last_name": "Karimov", "gender": "MALE", "role": "O'g'il", "birth_date": "2005-03-18", "created_at": "2024-01-15T08:00:00.000Z", "updated_at": "2024-01-15T08:00:00.000Z" }
    ]
  },
  {
    "id": 2, "region_id": 1, "district_id": 1, "created_by_agent_id": 1,
    "official_address": "Farg'ona sh., Navro'z ko'chasi, 7-uy",
    "house_number": "7",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Tinchlik MFY",
    "street_name": "Navro'z ko'chasi",
    "latitude": 40.3855, "longitude": 71.7840,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-01T09:00:00.000Z", "updated_at": "2024-02-01T09:00:00.000Z",
    "residents": [
      { "id": 4, "household_id": 2, "first_name": "Malika", "last_name": "Azimova", "phone_primary": "+998912223344", "gender": "FEMALE", "role": "Oila boshlig'i", "birth_date": "1975-11-05", "created_at": "2024-02-01T09:00:00.000Z", "updated_at": "2024-02-01T09:00:00.000Z" },
      { "id": 5, "household_id": 2, "first_name": "Kamola", "last_name": "Azimova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2008-07-14", "created_at": "2024-02-01T09:00:00.000Z", "updated_at": "2024-02-01T09:00:00.000Z" }
    ]
  },
  {
    "id": 3, "region_id": 1, "district_id": 1, "created_by_agent_id": 2,
    "official_address": "Farg'ona sh., S. Temur ko'chasi, 45-uy",
    "house_number": "45",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Yoshlik MFY",
    "street_name": "S. Temur ko'chasi",
    "latitude": 40.3900, "longitude": 71.7780,
    "is_verified": false, "is_active": true,
    "created_at": "2024-02-10T10:00:00.000Z", "updated_at": "2024-02-10T10:00:00.000Z",
    "residents": [
      { "id": 6, "household_id": 3, "first_name": "Sherzod", "last_name": "Tursunov", "phone_primary": "+998935556677", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1978-03-25", "created_at": "2024-02-10T10:00:00.000Z", "updated_at": "2024-02-10T10:00:00.000Z" },
      { "id": 7, "household_id": 3, "first_name": "Gulnora", "last_name": "Tursunova", "phone_primary": "+998935556688", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1980-09-12", "created_at": "2024-02-10T10:00:00.000Z", "updated_at": "2024-02-10T10:00:00.000Z" },
      { "id": 8, "household_id": 3, "first_name": "Asilbek", "last_name": "Tursunov", "gender": "MALE", "role": "O'g'il", "birth_date": "2010-01-30", "created_at": "2024-02-10T10:00:00.000Z", "updated_at": "2024-02-10T10:00:00.000Z" }
    ]
  },
  {
    "id": 4, "region_id": 1, "district_id": 1, "created_by_agent_id": 2,
    "official_address": "Farg'ona sh., Bog'ishamol ko'chasi, 3-uy",
    "house_number": "3",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Yoshlik MFY",
    "street_name": "Bog'ishamol ko'chasi",
    "latitude": 40.3920, "longitude": 71.7760,
    "is_verified": true, "is_active": true,
    "created_at": "2024-03-05T08:30:00.000Z", "updated_at": "2024-03-05T08:30:00.000Z",
    "residents": [
      { "id": 9, "household_id": 4, "first_name": "Mansur", "last_name": "Xolmatov", "phone_primary": "+998907778899", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1970-06-15", "created_at": "2024-03-05T08:30:00.000Z", "updated_at": "2024-03-05T08:30:00.000Z" }
    ]
  },
  {
    "id": 5, "region_id": 1, "district_id": 1, "created_by_agent_id": 1,
    "official_address": "Farg'ona sh., Istiqlol ko'chasi, 22-uy",
    "house_number": "22",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Markaziy MFY",
    "street_name": "Istiqlol ko'chasi",
    "latitude": 40.3870, "longitude": 71.7800,
    "is_verified": true, "is_active": true,
    "created_at": "2024-03-10T09:00:00.000Z", "updated_at": "2024-03-10T09:00:00.000Z",
    "residents": [
      { "id": 101, "household_id": 5, "first_name": "Ulmas", "last_name": "Hasanov", "phone_primary": "+998908887766", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1976-04-12", "created_at": "2024-03-10T09:00:00.000Z", "updated_at": "2024-03-10T09:00:00.000Z" },
      { "id": 102, "household_id": 5, "first_name": "Feruza", "last_name": "Hasanova", "phone_primary": "+998908887755", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1979-11-30", "created_at": "2024-03-10T09:00:00.000Z", "updated_at": "2024-03-10T09:00:00.000Z" }
    ]
  },
  {
    "id": 6, "region_id": 1, "district_id": 1, "created_by_agent_id": 2,
    "official_address": "Farg'ona sh., Istiqlol ko'chasi, 78-uy",
    "house_number": "78",
    "tuman_name": "Farg'ona shahri", "mfy_name": "Markaziy MFY",
    "street_name": "Istiqlol ko'chasi",
    "latitude": 40.3875, "longitude": 71.7810,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-12T08:00:00.000Z", "updated_at": "2024-03-12T08:00:00.000Z",
    "residents": [
      { "id": 103, "household_id": 6, "first_name": "Baxtiyor", "last_name": "Tojiboyev", "phone_primary": "+998941234567", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1982-07-08", "created_at": "2024-03-12T08:00:00.000Z", "updated_at": "2024-03-12T08:00:00.000Z" },
      { "id": 104, "household_id": 6, "first_name": "Sabohat", "last_name": "Tojiboyeva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1985-03-20", "created_at": "2024-03-12T08:00:00.000Z", "updated_at": "2024-03-12T08:00:00.000Z" },
      { "id": 105, "household_id": 6, "first_name": "Ibrohim", "last_name": "Tojiboyev", "gender": "MALE", "role": "O'g'il", "birth_date": "2013-09-05", "created_at": "2024-03-12T08:00:00.000Z", "updated_at": "2024-03-12T08:00:00.000Z" }
    ]
  },
  {
    "id": 7, "region_id": 1, "district_id": 2, "created_by_agent_id": 1,
    "official_address": "Marg'ilon sh., Navoiy ko'chasi, 88-uy",
    "house_number": "88",
    "tuman_name": "Marg'ilon shahri", "mfy_name": "Guliston MFY",
    "street_name": "Navoiy ko'chasi",
    "latitude": 40.4685, "longitude": 71.7330,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-20T08:00:00.000Z", "updated_at": "2024-01-20T08:00:00.000Z",
    "residents": [
      { "id": 10, "household_id": 7, "first_name": "Jasur", "last_name": "Hamidov", "phone_primary": "+998943334455", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1972-12-01", "created_at": "2024-01-20T08:00:00.000Z", "updated_at": "2024-01-20T08:00:00.000Z" },
      { "id": 11, "household_id": 7, "first_name": "Shahnoza", "last_name": "Hamidova", "phone_primary": "+998943334466", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1975-04-18", "created_at": "2024-01-20T08:00:00.000Z", "updated_at": "2024-01-20T08:00:00.000Z" },
      { "id": 12, "household_id": 7, "first_name": "Zulfiya", "last_name": "Hamidova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2003-08-20", "created_at": "2024-01-20T08:00:00.000Z", "updated_at": "2024-01-20T08:00:00.000Z" }
    ]
  },
  {
    "id": 8, "region_id": 1, "district_id": 2, "created_by_agent_id": 1,
    "official_address": "Marg'ilon sh., Ipak yo'li ko'chasi, 22-uy",
    "house_number": "22",
    "tuman_name": "Marg'ilon shahri", "mfy_name": "Guliston MFY",
    "street_name": "Ipak yo'li ko'chasi",
    "latitude": 40.4710, "longitude": 71.7310,
    "is_verified": false, "is_active": true,
    "created_at": "2024-02-05T09:15:00.000Z", "updated_at": "2024-02-05T09:15:00.000Z",
    "residents": [
      { "id": 13, "household_id": 8, "first_name": "Farrux", "last_name": "Yusupov", "phone_primary": "+998916667788", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1985-07-30", "created_at": "2024-02-05T09:15:00.000Z", "updated_at": "2024-02-05T09:15:00.000Z" },
      { "id": 14, "household_id": 8, "first_name": "Iroda", "last_name": "Yusupova", "phone_primary": "+998916667799", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1988-02-14", "created_at": "2024-02-05T09:15:00.000Z", "updated_at": "2024-02-05T09:15:00.000Z" }
    ]
  },
  {
    "id": 9, "region_id": 1, "district_id": 2, "created_by_agent_id": 2,
    "official_address": "Marg'ilon sh., Bog'bon ko'chasi, 9-uy",
    "house_number": "9",
    "tuman_name": "Marg'ilon shahri", "mfy_name": "Bahor MFY",
    "street_name": "Bog'bon ko'chasi",
    "latitude": 40.4660, "longitude": 71.7360,
    "is_verified": true, "is_active": true,
    "created_at": "2024-03-01T10:00:00.000Z", "updated_at": "2024-03-01T10:00:00.000Z",
    "residents": [
      { "id": 15, "household_id": 9, "first_name": "Ulug'bek", "last_name": "Nazarov", "phone_primary": "+998998889900", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1968-10-05", "created_at": "2024-03-01T10:00:00.000Z", "updated_at": "2024-03-01T10:00:00.000Z" },
      { "id": 16, "household_id": 9, "first_name": "Mohlaroyim", "last_name": "Nazarova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1972-03-19", "created_at": "2024-03-01T10:00:00.000Z", "updated_at": "2024-03-01T10:00:00.000Z" },
      { "id": 17, "household_id": 9, "first_name": "Shamsiya", "last_name": "Nazarova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2007-05-11", "created_at": "2024-03-01T10:00:00.000Z", "updated_at": "2024-03-01T10:00:00.000Z" }
    ]
  },
  {
    "id": 10, "region_id": 1, "district_id": 2, "created_by_agent_id": 1,
    "official_address": "Marg'ilon sh., Yangi Marg'ilon ko'chasi, 35-uy",
    "house_number": "35",
    "tuman_name": "Marg'ilon shahri", "mfy_name": "Bahor MFY",
    "street_name": "Yangi Marg'ilon ko'chasi",
    "latitude": 40.4670, "longitude": 71.7350,
    "is_verified": true, "is_active": true,
    "created_at": "2024-03-15T09:00:00.000Z", "updated_at": "2024-03-15T09:00:00.000Z",
    "residents": [
      { "id": 106, "household_id": 10, "first_name": "Nodir", "last_name": "Xo'jayev", "phone_primary": "+998977776655", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1984-01-25", "created_at": "2024-03-15T09:00:00.000Z", "updated_at": "2024-03-15T09:00:00.000Z" },
      { "id": 107, "household_id": 10, "first_name": "Zilola", "last_name": "Xo'jayeva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1987-06-14", "created_at": "2024-03-15T09:00:00.000Z", "updated_at": "2024-03-15T09:00:00.000Z" }
    ]
  },
  {
    "id": 11, "region_id": 1, "district_id": 3, "created_by_agent_id": 1,
    "official_address": "Qo'qon sh., Turkiston ko'chasi, 5-uy",
    "house_number": "5",
    "tuman_name": "Qo'qon shahri", "mfy_name": "Bog'ishamol MFY",
    "street_name": "Turkiston ko'chasi",
    "latitude": 40.5315, "longitude": 70.9410,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-25T08:00:00.000Z", "updated_at": "2024-01-25T08:00:00.000Z",
    "residents": [
      { "id": 18, "household_id": 11, "first_name": "Bekzod", "last_name": "Ismoilov", "phone_primary": "+998974445566", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1976-08-14", "created_at": "2024-01-25T08:00:00.000Z", "updated_at": "2024-01-25T08:00:00.000Z" },
      { "id": 19, "household_id": 11, "first_name": "Nozima", "last_name": "Ismoilova", "phone_primary": "+998974445577", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1979-11-28", "created_at": "2024-01-25T08:00:00.000Z", "updated_at": "2024-01-25T08:00:00.000Z" }
    ]
  },
  {
    "id": 12, "region_id": 1, "district_id": 3, "created_by_agent_id": 2,
    "official_address": "Qo'qon sh., Al-Farg'oniy ko'chasi, 31-uy",
    "house_number": "31",
    "tuman_name": "Qo'qon shahri", "mfy_name": "Bog'ishamol MFY",
    "street_name": "Al-Farg'oniy ko'chasi",
    "latitude": 40.5280, "longitude": 70.9450,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-14T10:00:00.000Z", "updated_at": "2024-02-14T10:00:00.000Z",
    "residents": [
      { "id": 20, "household_id": 12, "first_name": "Xurshid", "last_name": "Rahimov", "phone_primary": "+998911223344", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1982-04-04", "created_at": "2024-02-14T10:00:00.000Z", "updated_at": "2024-02-14T10:00:00.000Z" },
      { "id": 21, "household_id": 12, "first_name": "Maftuna", "last_name": "Rahimova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1985-09-22", "created_at": "2024-02-14T10:00:00.000Z", "updated_at": "2024-02-14T10:00:00.000Z" },
      { "id": 22, "household_id": 12, "first_name": "Doniyor", "last_name": "Rahimov", "gender": "MALE", "role": "O'g'il", "birth_date": "2012-06-17", "created_at": "2024-02-14T10:00:00.000Z", "updated_at": "2024-02-14T10:00:00.000Z" }
    ]
  },
  {
    "id": 13, "region_id": 1, "district_id": 3, "created_by_agent_id": 1,
    "official_address": "Qo'qon sh., Navruz ko'chasi, 67-uy",
    "house_number": "67",
    "tuman_name": "Qo'qon shahri", "mfy_name": "Markaz MFY",
    "street_name": "Navruz ko'chasi",
    "latitude": 40.5340, "longitude": 70.9380,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-10T08:00:00.000Z", "updated_at": "2024-03-10T08:00:00.000Z",
    "residents": [
      { "id": 23, "household_id": 13, "first_name": "Otabek", "last_name": "Solijonov", "phone_primary": "+998906667788", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1990-01-11", "created_at": "2024-03-10T08:00:00.000Z", "updated_at": "2024-03-10T08:00:00.000Z" }
    ]
  },
  {
    "id": 14, "region_id": 1, "district_id": 3, "created_by_agent_id": 2,
    "official_address": "Qo'qon sh., Amir Temur ko'chasi, 12-uy",
    "house_number": "12",
    "tuman_name": "Qo'qon shahri", "mfy_name": "Markaz MFY",
    "street_name": "Amir Temur ko'chasi",
    "latitude": 40.5325, "longitude": 70.9395,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-01T08:00:00.000Z", "updated_at": "2024-04-01T08:00:00.000Z",
    "residents": [
      { "id": 108, "household_id": 14, "first_name": "Jamshid", "last_name": "Pulatov", "phone_primary": "+998961112233", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1979-05-22", "created_at": "2024-04-01T08:00:00.000Z", "updated_at": "2024-04-01T08:00:00.000Z" },
      { "id": 109, "household_id": 14, "first_name": "Manzura", "last_name": "Pulatova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1981-10-14", "created_at": "2024-04-01T08:00:00.000Z", "updated_at": "2024-04-01T08:00:00.000Z" }
    ]
  },
  {
    "id": 15, "region_id": 1, "district_id": 4, "created_by_agent_id": 2,
    "official_address": "Oltiariq tumani, Markaziy ko'cha, 18-uy",
    "house_number": "18",
    "tuman_name": "Oltiariq tumani", "mfy_name": "Ittifok MFY",
    "street_name": "Markaziy ko'cha",
    "latitude": 40.3680, "longitude": 71.1740,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-20T09:00:00.000Z", "updated_at": "2024-02-20T09:00:00.000Z",
    "residents": [
      { "id": 24, "household_id": 15, "first_name": "Anvar", "last_name": "Qodirov", "phone_primary": "+998921112233", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1974-06-28", "created_at": "2024-02-20T09:00:00.000Z", "updated_at": "2024-02-20T09:00:00.000Z" },
      { "id": 25, "household_id": 15, "first_name": "Nasiba", "last_name": "Qodirova", "phone_primary": "+998921112244", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1977-10-14", "created_at": "2024-02-20T09:00:00.000Z", "updated_at": "2024-02-20T09:00:00.000Z" },
      { "id": 26, "household_id": 15, "first_name": "Muslima", "last_name": "Qodirova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2006-02-03", "created_at": "2024-02-20T09:00:00.000Z", "updated_at": "2024-02-20T09:00:00.000Z" }
    ]
  },
  {
    "id": 16, "region_id": 1, "district_id": 4, "created_by_agent_id": 1,
    "official_address": "Oltiariq tumani, Bog'lar ko'chasi, 2-uy",
    "house_number": "2",
    "tuman_name": "Oltiariq tumani", "mfy_name": "Ittifok MFY",
    "street_name": "Bog'lar ko'chasi",
    "latitude": 40.3700, "longitude": 71.1760,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-15T08:00:00.000Z", "updated_at": "2024-03-15T08:00:00.000Z",
    "residents": [
      { "id": 27, "household_id": 16, "first_name": "Go'zal", "last_name": "Mirzayeva", "phone_primary": "+998917778899", "gender": "FEMALE", "role": "Oila boshlig'i", "birth_date": "1969-12-20", "created_at": "2024-03-15T08:00:00.000Z", "updated_at": "2024-03-15T08:00:00.000Z" }
    ]
  },
  {
    "id": 17, "region_id": 1, "district_id": 4, "created_by_agent_id": 2,
    "official_address": "Oltiariq tumani, Navruz ko'chasi, 55-uy",
    "house_number": "55",
    "tuman_name": "Oltiariq tumani", "mfy_name": "Yangiobod MFY",
    "street_name": "Navruz ko'chasi",
    "latitude": 40.3720, "longitude": 71.1780,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-05T08:00:00.000Z", "updated_at": "2024-04-05T08:00:00.000Z",
    "residents": [
      { "id": 110, "household_id": 17, "first_name": "Eldor", "last_name": "Sobirov", "phone_primary": "+998952223344", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1986-08-17", "created_at": "2024-04-05T08:00:00.000Z", "updated_at": "2024-04-05T08:00:00.000Z" },
      { "id": 111, "household_id": 17, "first_name": "Dilorom", "last_name": "Sobirova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1989-02-28", "created_at": "2024-04-05T08:00:00.000Z", "updated_at": "2024-04-05T08:00:00.000Z" },
      { "id": 112, "household_id": 17, "first_name": "Sulton", "last_name": "Sobirov", "gender": "MALE", "role": "O'g'il", "birth_date": "2016-05-10", "created_at": "2024-04-05T08:00:00.000Z", "updated_at": "2024-04-05T08:00:00.000Z" }
    ]
  },
  {
    "id": 18, "region_id": 1, "district_id": 5, "created_by_agent_id": 2,
    "official_address": "Rishton tumani, Rishton ko'chasi, 10-uy",
    "house_number": "10",
    "tuman_name": "Rishton tumani", "mfy_name": "Ko'ktepa MFY",
    "street_name": "Rishton ko'chasi",
    "latitude": 40.3560, "longitude": 71.2850,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-30T08:00:00.000Z", "updated_at": "2024-01-30T08:00:00.000Z",
    "residents": [
      { "id": 28, "household_id": 18, "first_name": "G'olib", "last_name": "Rahmonov", "phone_primary": "+998905556677", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1971-08-30", "created_at": "2024-01-30T08:00:00.000Z", "updated_at": "2024-01-30T08:00:00.000Z" },
      { "id": 29, "household_id": 18, "first_name": "Barno", "last_name": "Rahmonova", "phone_primary": "+998905556688", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1974-03-16", "created_at": "2024-01-30T08:00:00.000Z", "updated_at": "2024-01-30T08:00:00.000Z" }
    ]
  },
  {
    "id": 19, "region_id": 1, "district_id": 5, "created_by_agent_id": 1,
    "official_address": "Rishton tumani, Gulzor ko'chasi, 55-uy",
    "house_number": "55",
    "tuman_name": "Rishton tumani", "mfy_name": "Ko'ktepa MFY",
    "street_name": "Gulzor ko'chasi",
    "latitude": 40.3580, "longitude": 71.2830,
    "is_verified": false, "is_active": true,
    "created_at": "2024-02-25T09:00:00.000Z", "updated_at": "2024-02-25T09:00:00.000Z",
    "residents": [
      { "id": 30, "household_id": 19, "first_name": "Sanjar", "last_name": "Toshpulatov", "phone_primary": "+998949990011", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1988-05-22", "created_at": "2024-02-25T09:00:00.000Z", "updated_at": "2024-02-25T09:00:00.000Z" },
      { "id": 31, "household_id": 19, "first_name": "Lola", "last_name": "Toshpulatova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1991-11-08", "created_at": "2024-02-25T09:00:00.000Z", "updated_at": "2024-02-25T09:00:00.000Z" },
      { "id": 32, "household_id": 19, "first_name": "Temur", "last_name": "Toshpulatov", "gender": "MALE", "role": "O'g'il", "birth_date": "2015-04-02", "created_at": "2024-02-25T09:00:00.000Z", "updated_at": "2024-02-25T09:00:00.000Z" }
    ]
  },
  {
    "id": 20, "region_id": 1, "district_id": 5, "created_by_agent_id": 2,
    "official_address": "Rishton tumani, Bog'cha ko'chasi, 8-uy",
    "house_number": "8",
    "tuman_name": "Rishton tumani", "mfy_name": "Marhamat MFY",
    "street_name": "Bog'cha ko'chasi",
    "latitude": 40.3570, "longitude": 71.2865,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-10T08:00:00.000Z", "updated_at": "2024-04-10T08:00:00.000Z",
    "residents": [
      { "id": 113, "household_id": 20, "first_name": "Hamidjon", "last_name": "Ergashev", "phone_primary": "+998963334455", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1973-11-18", "created_at": "2024-04-10T08:00:00.000Z", "updated_at": "2024-04-10T08:00:00.000Z" },
      { "id": 114, "household_id": 20, "first_name": "Mohichehra", "last_name": "Ergasheva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1976-07-22", "created_at": "2024-04-10T08:00:00.000Z", "updated_at": "2024-04-10T08:00:00.000Z" }
    ]
  },
  {
    "id": 21, "region_id": 1, "district_id": 6, "created_by_agent_id": 1,
    "official_address": "Quva tumani, Guliston ko'chasi, 33-uy",
    "house_number": "33",
    "tuman_name": "Quva tumani", "mfy_name": "G'alaba MFY",
    "street_name": "Guliston ko'chasi",
    "latitude": 40.5210, "longitude": 72.0120,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-08T08:00:00.000Z", "updated_at": "2024-02-08T08:00:00.000Z",
    "residents": [
      { "id": 33, "household_id": 21, "first_name": "Ziyoda", "last_name": "Umarova", "phone_primary": "+998991110099", "gender": "FEMALE", "role": "Oila boshlig'i", "birth_date": "1979-06-10", "created_at": "2024-02-08T08:00:00.000Z", "updated_at": "2024-02-08T08:00:00.000Z" },
      { "id": 34, "household_id": 21, "first_name": "Hamza", "last_name": "Umarov", "gender": "MALE", "role": "O'g'il", "birth_date": "2009-03-25", "created_at": "2024-02-08T08:00:00.000Z", "updated_at": "2024-02-08T08:00:00.000Z" }
    ]
  },
  {
    "id": 22, "region_id": 1, "district_id": 6, "created_by_agent_id": 2,
    "official_address": "Quva tumani, Yoshlik ko'chasi, 12-uy",
    "house_number": "12",
    "tuman_name": "Quva tumani", "mfy_name": "G'alaba MFY",
    "street_name": "Yoshlik ko'chasi",
    "latitude": 40.5230, "longitude": 72.0100,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-12T09:00:00.000Z", "updated_at": "2024-03-12T09:00:00.000Z",
    "residents": [
      { "id": 35, "household_id": 22, "first_name": "Ravshan", "last_name": "Sobirov", "phone_primary": "+998981234567", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1993-07-18", "created_at": "2024-03-12T09:00:00.000Z", "updated_at": "2024-03-12T09:00:00.000Z" }
    ]
  },
  {
    "id": 23, "region_id": 1, "district_id": 6, "created_by_agent_id": 1,
    "official_address": "Quva tumani, Paxtakor ko'chasi, 41-uy",
    "house_number": "41",
    "tuman_name": "Quva tumani", "mfy_name": "Tinchlik MFY",
    "street_name": "Paxtakor ko'chasi",
    "latitude": 40.5245, "longitude": 72.0140,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-12T08:00:00.000Z", "updated_at": "2024-04-12T08:00:00.000Z",
    "residents": [
      { "id": 115, "household_id": 23, "first_name": "Nurbek", "last_name": "Qosimov", "phone_primary": "+998987654321", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1981-03-14", "created_at": "2024-04-12T08:00:00.000Z", "updated_at": "2024-04-12T08:00:00.000Z" },
      { "id": 116, "household_id": 23, "first_name": "Gulbahor", "last_name": "Qosimova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1984-09-30", "created_at": "2024-04-12T08:00:00.000Z", "updated_at": "2024-04-12T08:00:00.000Z" },
      { "id": 117, "household_id": 23, "first_name": "Nilufar", "last_name": "Qosimova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2011-12-01", "created_at": "2024-04-12T08:00:00.000Z", "updated_at": "2024-04-12T08:00:00.000Z" }
    ]
  },
  {
    "id": 24, "region_id": 1, "district_id": 7, "created_by_agent_id": 1,
    "official_address": "Farg'ona tumani, Bog' ko'chasi, 6-uy",
    "house_number": "6",
    "tuman_name": "Farg'ona tumani", "mfy_name": "Shirin MFY",
    "street_name": "Bog' ko'chasi",
    "latitude": 40.3750, "longitude": 71.8050,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-18T08:00:00.000Z", "updated_at": "2024-01-18T08:00:00.000Z",
    "residents": [
      { "id": 36, "household_id": 24, "first_name": "Alisher", "last_name": "Sodiqov", "phone_primary": "+998901234567", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1980-05-10", "created_at": "2024-01-18T08:00:00.000Z", "updated_at": "2024-01-18T08:00:00.000Z" },
      { "id": 37, "household_id": 24, "first_name": "Nargiza", "last_name": "Sodiqova", "phone_primary": "+998901234568", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1983-09-14", "created_at": "2024-01-18T08:00:00.000Z", "updated_at": "2024-01-18T08:00:00.000Z" },
      { "id": 38, "household_id": 24, "first_name": "Eldor", "last_name": "Sodiqov", "gender": "MALE", "role": "O'g'il", "birth_date": "2011-12-05", "created_at": "2024-01-18T08:00:00.000Z", "updated_at": "2024-01-18T08:00:00.000Z" }
    ]
  },
  {
    "id": 25, "region_id": 1, "district_id": 7, "created_by_agent_id": 2,
    "official_address": "Farg'ona tumani, Yangi ko'cha, 44-uy",
    "house_number": "44",
    "tuman_name": "Farg'ona tumani", "mfy_name": "Shirin MFY",
    "street_name": "Yangi ko'cha",
    "latitude": 40.3760, "longitude": 71.8060,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-20T09:00:00.000Z", "updated_at": "2024-03-20T09:00:00.000Z",
    "residents": [
      { "id": 39, "household_id": 25, "first_name": "Komiljon", "last_name": "Nazarov", "phone_primary": "+998946667788", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1991-02-22", "created_at": "2024-03-20T09:00:00.000Z", "updated_at": "2024-03-20T09:00:00.000Z" },
      { "id": 40, "household_id": 25, "first_name": "Shahlo", "last_name": "Nazarova", "phone_primary": "+998946667799", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1993-08-30", "created_at": "2024-03-20T09:00:00.000Z", "updated_at": "2024-03-20T09:00:00.000Z" }
    ]
  },
  {
    "id": 26, "region_id": 1, "district_id": 7, "created_by_agent_id": 1,
    "official_address": "Farg'ona tumani, Mustaqillik ko'chasi, 17-uy",
    "house_number": "17",
    "tuman_name": "Farg'ona tumani", "mfy_name": "Navbahor MFY",
    "street_name": "Mustaqillik ko'chasi",
    "latitude": 40.3780, "longitude": 71.8070,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-08T09:00:00.000Z", "updated_at": "2024-04-08T09:00:00.000Z",
    "residents": [
      { "id": 118, "household_id": 26, "first_name": "Sarvar", "last_name": "Mirzaev", "phone_primary": "+998912345678", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1977-09-06", "created_at": "2024-04-08T09:00:00.000Z", "updated_at": "2024-04-08T09:00:00.000Z" },
      { "id": 119, "household_id": 26, "first_name": "Zuhra", "last_name": "Mirzaeva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1980-04-15", "created_at": "2024-04-08T09:00:00.000Z", "updated_at": "2024-04-08T09:00:00.000Z" }
    ]
  },
  {
    "id": 27, "region_id": 1, "district_id": 8, "created_by_agent_id": 1,
    "official_address": "Uchko'prik tumani, Markaziy ko'cha, 8-uy",
    "house_number": "8",
    "tuman_name": "Uchko'prik tumani", "mfy_name": "Navbahor MFY",
    "street_name": "Markaziy ko'cha",
    "latitude": 40.2850, "longitude": 71.6320,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-28T08:00:00.000Z", "updated_at": "2024-02-28T08:00:00.000Z",
    "residents": [
      { "id": 41, "household_id": 27, "first_name": "Dilshod", "last_name": "Toshmatov", "phone_primary": "+998939876543", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1977-04-09", "created_at": "2024-02-28T08:00:00.000Z", "updated_at": "2024-02-28T08:00:00.000Z" },
      { "id": 42, "household_id": 27, "first_name": "Manzura", "last_name": "Toshmatova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1980-11-25", "created_at": "2024-02-28T08:00:00.000Z", "updated_at": "2024-02-28T08:00:00.000Z" }
    ]
  },
  {
    "id": 28, "region_id": 1, "district_id": 8, "created_by_agent_id": 2,
    "official_address": "Uchko'prik tumani, Bog'lar ko'chasi, 34-uy",
    "house_number": "34",
    "tuman_name": "Uchko'prik tumani", "mfy_name": "Navbahor MFY",
    "street_name": "Bog'lar ko'chasi",
    "latitude": 40.2870, "longitude": 71.6340,
    "is_verified": false, "is_active": true,
    "created_at": "2024-04-02T09:00:00.000Z", "updated_at": "2024-04-02T09:00:00.000Z",
    "residents": [
      { "id": 120, "household_id": 28, "first_name": "Abdulaziz", "last_name": "Yo'ldoshev", "phone_primary": "+998955554433", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1983-12-03", "created_at": "2024-04-02T09:00:00.000Z", "updated_at": "2024-04-02T09:00:00.000Z" },
      { "id": 121, "household_id": 28, "first_name": "Hulkar", "last_name": "Yo'ldosheva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1987-06-18", "created_at": "2024-04-02T09:00:00.000Z", "updated_at": "2024-04-02T09:00:00.000Z" }
    ]
  },
  {
    "id": 29, "region_id": 1, "district_id": 9, "created_by_agent_id": 2,
    "official_address": "O'zbekiston tumani, Go'zal diyor ko'chasi, 156-uy",
    "house_number": "156",
    "tuman_name": "O'zbekiston tumani", "mfy_name": "Yakkatut MFY",
    "street_name": "Go'zal diyor ko'chasi",
    "latitude": 40.4402, "longitude": 70.8833,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-10T08:00:00.000Z", "updated_at": "2024-01-10T08:00:00.000Z",
    "residents": [
      { "id": 43, "household_id": 29, "first_name": "Alisher", "last_name": "Xoliqov", "phone_primary": "+998901234999", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1973-07-17", "created_at": "2024-01-10T08:00:00.000Z", "updated_at": "2024-01-10T08:00:00.000Z" },
      { "id": 44, "household_id": 29, "first_name": "Nodira", "last_name": "Xoliqova", "phone_primary": "+998901235000", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1976-09-03", "created_at": "2024-01-10T08:00:00.000Z", "updated_at": "2024-01-10T08:00:00.000Z" },
      { "id": 45, "household_id": 29, "first_name": "Jasurbek", "last_name": "Xoliqov", "gender": "MALE", "role": "O'g'il", "birth_date": "2004-01-12", "created_at": "2024-01-10T08:00:00.000Z", "updated_at": "2024-01-10T08:00:00.000Z" },
      { "id": 46, "household_id": 29, "first_name": "Mohira", "last_name": "Xoliqova", "gender": "FEMALE", "role": "Qiz", "birth_date": "2009-06-20", "created_at": "2024-01-10T08:00:00.000Z", "updated_at": "2024-01-10T08:00:00.000Z" }
    ]
  },
  {
    "id": 30, "region_id": 1, "district_id": 9, "created_by_agent_id": 1,
    "official_address": "O'zbekiston tumani, Fayzobod ko'chasi, 27-uy",
    "house_number": "27",
    "tuman_name": "O'zbekiston tumani", "mfy_name": "Yakkatut MFY",
    "street_name": "Fayzobod ko'chasi",
    "latitude": 40.4415, "longitude": 70.8850,
    "is_verified": false, "is_active": true,
    "created_at": "2024-04-15T08:00:00.000Z", "updated_at": "2024-04-15T08:00:00.000Z",
    "residents": [
      { "id": 122, "household_id": 30, "first_name": "Shokir", "last_name": "Tursunov", "phone_primary": "+998971231234", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1975-02-11", "created_at": "2024-04-15T08:00:00.000Z", "updated_at": "2024-04-15T08:00:00.000Z" },
      { "id": 123, "household_id": 30, "first_name": "Rayhona", "last_name": "Tursunova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1978-08-04", "created_at": "2024-04-15T08:00:00.000Z", "updated_at": "2024-04-15T08:00:00.000Z" }
    ]
  },
  {
    "id": 31, "region_id": 1, "district_id": 10, "created_by_agent_id": 1,
    "official_address": "Bag'dod tumani, Mustaqillik ko'chasi, 19-uy",
    "house_number": "19",
    "tuman_name": "Bag'dod tumani", "mfy_name": "Navro'z MFY",
    "street_name": "Mustaqillik ko'chasi",
    "latitude": 40.5030, "longitude": 70.7620,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-05T08:00:00.000Z", "updated_at": "2024-01-05T08:00:00.000Z",
    "residents": [
      { "id": 50, "household_id": 31, "first_name": "Muzaffar", "last_name": "Sharipov", "phone_primary": "+998930001122", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1969-04-20", "created_at": "2024-01-05T08:00:00.000Z", "updated_at": "2024-01-05T08:00:00.000Z" },
      { "id": 51, "household_id": 31, "first_name": "Saodat", "last_name": "Sharipova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1972-10-09", "created_at": "2024-01-05T08:00:00.000Z", "updated_at": "2024-01-05T08:00:00.000Z" },
      { "id": 52, "household_id": 31, "first_name": "Mansurbek", "last_name": "Sharipov", "gender": "MALE", "role": "O'g'il", "birth_date": "2000-07-15", "created_at": "2024-01-05T08:00:00.000Z", "updated_at": "2024-01-05T08:00:00.000Z" }
    ]
  },
  {
    "id": 32, "region_id": 1, "district_id": 10, "created_by_agent_id": 2,
    "official_address": "Bag'dod tumani, Bog'cha ko'chasi, 4-uy",
    "house_number": "4",
    "tuman_name": "Bag'dod tumani", "mfy_name": "Navro'z MFY",
    "street_name": "Bog'cha ko'chasi",
    "latitude": 40.5040, "longitude": 70.7630,
    "is_verified": false, "is_active": true,
    "created_at": "2024-03-25T09:00:00.000Z", "updated_at": "2024-03-25T09:00:00.000Z",
    "residents": [
      { "id": 124, "household_id": 32, "first_name": "Asror", "last_name": "Qoraboyev", "phone_primary": "+998966543210", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1987-06-25", "created_at": "2024-03-25T09:00:00.000Z", "updated_at": "2024-03-25T09:00:00.000Z" }
    ]
  },
  {
    "id": 33, "region_id": 1, "district_id": 11, "created_by_agent_id": 1,
    "official_address": "Beshariq tumani, Gulkor ko'chasi, 29-uy",
    "house_number": "29",
    "tuman_name": "Beshariq tumani", "mfy_name": "Bahor MFY",
    "street_name": "Gulkor ko'chasi",
    "latitude": 40.4320, "longitude": 70.5980,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-03T08:00:00.000Z", "updated_at": "2024-02-03T08:00:00.000Z",
    "residents": [
      { "id": 60, "household_id": 33, "first_name": "Husan", "last_name": "Ortiqov", "phone_primary": "+998912223355", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1975-09-12", "created_at": "2024-02-03T08:00:00.000Z", "updated_at": "2024-02-03T08:00:00.000Z" },
      { "id": 61, "household_id": 33, "first_name": "Mavluda", "last_name": "Ortiqova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1978-04-28", "created_at": "2024-02-03T08:00:00.000Z", "updated_at": "2024-02-03T08:00:00.000Z" }
    ]
  },
  {
    "id": 34, "region_id": 1, "district_id": 11, "created_by_agent_id": 2,
    "official_address": "Beshariq tumani, Yangi hayot ko'chasi, 13-uy",
    "house_number": "13",
    "tuman_name": "Beshariq tumani", "mfy_name": "Bahor MFY",
    "street_name": "Yangi hayot ko'chasi",
    "latitude": 40.4335, "longitude": 70.5995,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-06T08:00:00.000Z", "updated_at": "2024-04-06T08:00:00.000Z",
    "residents": [
      { "id": 125, "household_id": 34, "first_name": "Islom", "last_name": "Baxtiyorov", "phone_primary": "+998978764321", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1989-12-17", "created_at": "2024-04-06T08:00:00.000Z", "updated_at": "2024-04-06T08:00:00.000Z" },
      { "id": 126, "household_id": 34, "first_name": "Barnogul", "last_name": "Baxtiyorova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1992-07-08", "created_at": "2024-04-06T08:00:00.000Z", "updated_at": "2024-04-06T08:00:00.000Z" },
      { "id": 127, "household_id": 34, "first_name": "Oybek", "last_name": "Baxtiyorov", "gender": "MALE", "role": "O'g'il", "birth_date": "2018-03-22", "created_at": "2024-04-06T08:00:00.000Z", "updated_at": "2024-04-06T08:00:00.000Z" }
    ]
  },
  {
    "id": 35, "region_id": 1, "district_id": 12, "created_by_agent_id": 1,
    "official_address": "Dang'ara tumani, O'rta ko'cha, 63-uy",
    "house_number": "63",
    "tuman_name": "Dang'ara tumani", "mfy_name": "Sariqtepa MFY",
    "street_name": "O'rta ko'cha",
    "latitude": 40.4900, "longitude": 71.1010,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-22T08:00:00.000Z", "updated_at": "2024-01-22T08:00:00.000Z",
    "residents": [
      { "id": 70, "household_id": 35, "first_name": "Akbar", "last_name": "Usmonov", "phone_primary": "+998944433221", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1971-02-14", "created_at": "2024-01-22T08:00:00.000Z", "updated_at": "2024-01-22T08:00:00.000Z" },
      { "id": 71, "household_id": 35, "first_name": "Nafisa", "last_name": "Usmonova", "phone_primary": "+998944433232", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1974-06-30", "created_at": "2024-01-22T08:00:00.000Z", "updated_at": "2024-01-22T08:00:00.000Z" }
    ]
  },
  {
    "id": 36, "region_id": 1, "district_id": 12, "created_by_agent_id": 2,
    "official_address": "Dang'ara tumani, Bog'bon ko'chasi, 11-uy",
    "house_number": "11",
    "tuman_name": "Dang'ara tumani", "mfy_name": "Sariqtepa MFY",
    "street_name": "Bog'bon ko'chasi",
    "latitude": 40.4915, "longitude": 71.1025,
    "is_verified": false, "is_active": true,
    "created_at": "2024-04-18T09:00:00.000Z", "updated_at": "2024-04-18T09:00:00.000Z",
    "residents": [
      { "id": 128, "household_id": 36, "first_name": "Qodir", "last_name": "Nishonov", "phone_primary": "+998937896543", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1980-11-02", "created_at": "2024-04-18T09:00:00.000Z", "updated_at": "2024-04-18T09:00:00.000Z" }
    ]
  },
  {
    "id": 37, "region_id": 1, "district_id": 13, "created_by_agent_id": 1,
    "official_address": "Yozyovon tumani, Bog'ishamol ko'chasi, 48-uy",
    "house_number": "48",
    "tuman_name": "Yozyovon tumani", "mfy_name": "Ziyodabod MFY",
    "street_name": "Bog'ishamol ko'chasi",
    "latitude": 40.2520, "longitude": 71.0860,
    "is_verified": true, "is_active": true,
    "created_at": "2024-02-18T08:00:00.000Z", "updated_at": "2024-02-18T08:00:00.000Z",
    "residents": [
      { "id": 80, "household_id": 37, "first_name": "Tohir", "last_name": "Ruziyev", "phone_primary": "+998925553322", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1966-08-05", "created_at": "2024-02-18T08:00:00.000Z", "updated_at": "2024-02-18T08:00:00.000Z" },
      { "id": 81, "household_id": 37, "first_name": "Tursunoy", "last_name": "Ruziyeva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1970-12-19", "created_at": "2024-02-18T08:00:00.000Z", "updated_at": "2024-02-18T08:00:00.000Z" }
    ]
  },
  {
    "id": 38, "region_id": 1, "district_id": 13, "created_by_agent_id": 2,
    "official_address": "Yozyovon tumani, Tinchlik ko'chasi, 7-uy",
    "house_number": "7",
    "tuman_name": "Yozyovon tumani", "mfy_name": "Ziyodabod MFY",
    "street_name": "Tinchlik ko'chasi",
    "latitude": 40.2535, "longitude": 71.0875,
    "is_verified": true, "is_active": true,
    "created_at": "2024-04-20T09:00:00.000Z", "updated_at": "2024-04-20T09:00:00.000Z",
    "residents": [
      { "id": 129, "household_id": 38, "first_name": "Muxammad", "last_name": "Valiyev", "phone_primary": "+998919998877", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1993-03-27", "created_at": "2024-04-20T09:00:00.000Z", "updated_at": "2024-04-20T09:00:00.000Z" },
      { "id": 130, "household_id": 38, "first_name": "Kamola", "last_name": "Valiyeva", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1995-10-13", "created_at": "2024-04-20T09:00:00.000Z", "updated_at": "2024-04-20T09:00:00.000Z" }
    ]
  },
  {
    "id": 39, "region_id": 1, "district_id": 14, "created_by_agent_id": 1,
    "official_address": "Toshloq tumani, Navro'z ko'chasi, 82-uy",
    "house_number": "82",
    "tuman_name": "Toshloq tumani", "mfy_name": "Bog'lar MFY",
    "street_name": "Navro'z ko'chasi",
    "latitude": 40.3250, "longitude": 71.9400,
    "is_verified": true, "is_active": true,
    "created_at": "2024-01-28T08:00:00.000Z", "updated_at": "2024-01-28T08:00:00.000Z",
    "residents": [
      { "id": 90, "household_id": 39, "first_name": "Firdavs", "last_name": "Normatov", "phone_primary": "+998931112233", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1978-05-18", "created_at": "2024-01-28T08:00:00.000Z", "updated_at": "2024-01-28T08:00:00.000Z" },
      { "id": 91, "household_id": 39, "first_name": "Umida", "last_name": "Normatova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1981-11-03", "created_at": "2024-01-28T08:00:00.000Z", "updated_at": "2024-01-28T08:00:00.000Z" },
      { "id": 92, "household_id": 39, "first_name": "Bobir", "last_name": "Normatov", "gender": "MALE", "role": "O'g'il", "birth_date": "2009-08-14", "created_at": "2024-01-28T08:00:00.000Z", "updated_at": "2024-01-28T08:00:00.000Z" }
    ]
  },
  {
    "id": 40, "region_id": 1, "district_id": 14, "created_by_agent_id": 2,
    "official_address": "Toshloq tumani, Istiqlol ko'chasi, 5-uy",
    "house_number": "5",
    "tuman_name": "Toshloq tumani", "mfy_name": "Bog'lar MFY",
    "street_name": "Istiqlol ko'chasi",
    "latitude": 40.3265, "longitude": 71.9415,
    "is_verified": false, "is_active": true,
    "created_at": "2024-04-22T09:00:00.000Z", "updated_at": "2024-04-22T09:00:00.000Z",
    "residents": [
      { "id": 131, "household_id": 40, "first_name": "Shuhrat", "last_name": "Aminov", "phone_primary": "+998948887766", "gender": "MALE", "role": "Oila boshlig'i", "birth_date": "1986-01-09", "created_at": "2024-04-22T09:00:00.000Z", "updated_at": "2024-04-22T09:00:00.000Z" },
      { "id": 132, "household_id": 40, "first_name": "Mohlaroyim", "last_name": "Aminova", "gender": "FEMALE", "role": "Turmush o'rtog'i", "birth_date": "1989-07-25", "created_at": "2024-04-22T09:00:00.000Z", "updated_at": "2024-04-22T09:00:00.000Z" },
      { "id": 133, "household_id": 40, "first_name": "Suhrob", "last_name": "Aminov", "gender": "MALE", "role": "O'g'il", "birth_date": "2014-04-11", "created_at": "2024-04-22T09:00:00.000Z", "updated_at": "2024-04-22T09:00:00.000Z" }
    ]
  }
]
''';
