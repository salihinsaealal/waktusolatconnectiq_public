using Toybox.Lang;

// Malaysian States and Districts with Coordinates
class MalaysianLocations {
    
    // Get all Malaysian states
    static function getStates() {
        return [
            {"id" => "johor", "name" => "Johor"},
            {"id" => "kedah", "name" => "Kedah"},
            {"id" => "kelantan", "name" => "Kelantan"},
            {"id" => "melaka", "name" => "Melaka"},
            {"id" => "negeri_sembilan", "name" => "Negeri Sembilan"},
            {"id" => "pahang", "name" => "Pahang"},
            {"id" => "perak", "name" => "Perak"},
            {"id" => "perlis", "name" => "Perlis"},
            {"id" => "penang", "name" => "Pulau Pinang"},
            {"id" => "sabah", "name" => "Sabah"},
            {"id" => "sarawak", "name" => "Sarawak"},
            {"id" => "selangor", "name" => "Selangor"},
            {"id" => "terengganu", "name" => "Terengganu"},
            {"id" => "kl", "name" => "Kuala Lumpur"},
            {"id" => "putrajaya", "name" => "Putrajaya"},
            {"id" => "labuan", "name" => "Labuan"}
        ];
    }
    
    // Get districts for a specific state
    static function getDistricts(stateId) {
        switch (stateId) {
            case "johor":
                return [
                    {"name" => "Johor Bahru", "lat" => 1.4927f, "lon" => 103.7414f},
                    {"name" => "Muar", "lat" => 2.0442f, "lon" => 102.5689f},
                    {"name" => "Batu Pahat", "lat" => 1.8546f, "lon" => 102.9326f},
                    {"name" => "Kluang", "lat" => 2.0306f, "lon" => 103.3186f},
                    {"name" => "Mersing", "lat" => 2.4312f, "lon" => 103.8405f},
                    {"name" => "Pontian", "lat" => 1.4869f, "lon" => 103.3890f},
                    {"name" => "Segamat", "lat" => 2.5154f, "lon" => 102.8154f},
                    {"name" => "Kota Tinggi", "lat" => 1.7378f, "lon" => 103.8998f},
                    {"name" => "Kulai", "lat" => 1.6667f, "lon" => 103.6000f},
                    {"name" => "Tangkak", "lat" => 2.2667f, "lon" => 102.5833f}
                ];
                
            case "kedah":
                return [
                    {"name" => "Alor Setar", "lat" => 6.1248f, "lon" => 100.3678f},
                    {"name" => "Sungai Petani", "lat" => 5.6470f, "lon" => 100.4871f},
                    {"name" => "Kulim", "lat" => 5.3647f, "lon" => 100.5616f},
                    {"name" => "Langkawi", "lat" => 6.3500f, "lon" => 99.8000f},
                    {"name" => "Kuala Muda", "lat" => 5.5333f, "lon" => 100.4167f},
                    {"name" => "Yan", "lat" => 5.7667f, "lon" => 100.4000f},
                    {"name" => "Pendang", "lat" => 5.9833f, "lon" => 100.5000f},
                    {"name" => "Kuala Nerang", "lat" => 6.0167f, "lon" => 100.6167f},
                    {"name" => "Pokok Sena", "lat" => 6.1167f, "lon" => 100.4833f},
                    {"name" => "Padang Terap", "lat" => 6.2167f, "lon" => 100.8500f}
                ];
                
            case "kelantan":
                return [
                    {"name" => "Kota Bharu", "lat" => 6.1254f, "lon" => 102.2386f},
                    {"name" => "Tanah Merah", "lat" => 5.8000f, "lon" => 102.1500f},
                    {"name" => "Machang", "lat" => 5.7667f, "lon" => 102.2167f},
                    {"name" => "Pasir Mas", "lat" => 6.0500f, "lon" => 102.1333f},
                    {"name" => "Tumpat", "lat" => 6.2000f, "lon" => 102.1667f},
                    {"name" => "Bachok", "lat" => 6.0167f, "lon" => 102.4167f},
                    {"name" => "Kuala Krai", "lat" => 5.5333f, "lon" => 102.2000f},
                    {"name" => "Gua Musang", "lat" => 4.8833f, "lon" => 101.9667f},
                    {"name" => "Jeli", "lat" => 5.7000f, "lon" => 101.8500f},
                    {"name" => "Pasir Puteh", "lat" => 5.8333f, "lon" => 102.4000f}
                ];
                
            case "melaka":
                return [
                    {"name" => "Melaka Tengah", "lat" => 2.1896f, "lon" => 102.2501f},
                    {"name" => "Alor Gajah", "lat" => 2.3794f, "lon" => 102.2088f},
                    {"name" => "Jasin", "lat" => 2.3176f, "lon" => 102.4341f},
                    {"name" => "Masjid Tanah", "lat" => 2.3500f, "lon" => 102.1167f},
                    {"name" => "Merlimau", "lat" => 2.3833f, "lon" => 102.4167f}
                ];
                
            case "negeri_sembilan":
                return [
                    {"name" => "Seremban", "lat" => 2.7297f, "lon" => 101.9381f},
                    {"name" => "Port Dickson", "lat" => 2.5420f, "lon" => 101.7971f},
                    {"name" => "Rembau", "lat" => 2.5833f, "lon" => 102.0833f},
                    {"name" => "Tampin", "lat" => 2.4667f, "lon" => 102.2333f},
                    {"name" => "Kuala Pilah", "lat" => 2.7333f, "lon" => 102.2500f},
                    {"name" => "Jelebu", "lat" => 2.9667f, "lon" => 102.0167f},
                    {"name" => "Jempol", "lat" => 2.8167f, "lon" => 102.3500f}
                ];
                
            case "pahang":
                return [
                    {"name" => "Kuantan", "lat" => 3.8077f, "lon" => 103.3260f},
                    {"name" => "Temerloh", "lat" => 3.4500f, "lon" => 102.4167f},
                    {"name" => "Bentong", "lat" => 3.5167f, "lon" => 101.9000f},
                    {"name" => "Raub", "lat" => 3.7833f, "lon" => 101.8667f},
                    {"name" => "Kuala Lipis", "lat" => 4.1833f, "lon" => 102.0500f},
                    {"name" => "Jerantut", "lat" => 3.9333f, "lon" => 102.3667f},
                    {"name" => "Maran", "lat" => 3.5500f, "lon" => 102.8000f},
                    {"name" => "Pekan", "lat" => 3.4833f, "lon" => 103.4000f},
                    {"name" => "Rompin", "lat" => 2.8167f, "lon" => 103.2167f},
                    {"name" => "Bera", "lat" => 3.1833f, "lon" => 102.6000f},
                    {"name" => "Cameron Highlands", "lat" => 4.4667f, "lon" => 101.3833f}
                ];
                
            case "perak":
                return [
                    {"name" => "Ipoh", "lat" => 4.5975f, "lon" => 101.0901f},
                    {"name" => "Taiping", "lat" => 4.8500f, "lon" => 100.7333f},
                    {"name" => "Teluk Intan", "lat" => 4.0167f, "lon" => 101.0167f},
                    {"name" => "Kuala Kangsar", "lat" => 4.7667f, "lon" => 100.9333f},
                    {"name" => "Seri Iskandar", "lat" => 4.3833f, "lon" => 100.9667f},
                    {"name" => "Parit Buntar", "lat" => 5.1167f, "lon" => 100.4833f},
                    {"name" => "Lumut", "lat" => 4.2333f, "lon" => 100.6333f},
                    {"name" => "Sitiawan", "lat" => 4.2167f, "lon" => 100.7000f},
                    {"name" => "Kampar", "lat" => 4.3167f, "lon" => 101.1500f},
                    {"name" => "Bagan Serai", "lat" => 5.0167f, "lon" => 100.5500f},
                    {"name" => "Tanjung Malim", "lat" => 3.6833f, "lon" => 101.5167f},
                    {"name" => "Gerik", "lat" => 5.4167f, "lon" => 101.1167f}
                ];
                
            case "perlis":
                return [
                    {"name" => "Kangar", "lat" => 6.4414f, "lon" => 100.1986f},
                    {"name" => "Arau", "lat" => 6.4333f, "lon" => 100.2667f},
                    {"name" => "Padang Besar", "lat" => 6.6600f, "lon" => 100.3200f}
                ];
                
            case "penang":
                return [
                    {"name" => "George Town", "lat" => 5.4141f, "lon" => 100.3288f},
                    {"name" => "Butterworth", "lat" => 5.3991f, "lon" => 100.3635f},
                    {"name" => "Bukit Mertajam", "lat" => 5.3617f, "lon" => 100.4589f},
                    {"name" => "Nibong Tebal", "lat" => 5.1667f, "lon" => 100.4833f},
                    {"name" => "Kepala Batas", "lat" => 5.5167f, "lon" => 100.3833f},
                    {"name" => "Balik Pulau", "lat" => 5.3500f, "lon" => 100.2333f}
                ];
                
            case "sabah":
                return [
                    {"name" => "Kota Kinabalu", "lat" => 5.9804f, "lon" => 116.0735f},
                    {"name" => "Sandakan", "lat" => 5.8402f, "lon" => 118.1179f},
                    {"name" => "Tawau", "lat" => 4.2502f, "lon" => 117.8794f},
                    {"name" => "Lahad Datu", "lat" => 5.0267f, "lon" => 118.3267f},
                    {"name" => "Keningau", "lat" => 5.3386f, "lon" => 116.1594f},
                    {"name" => "Kudat", "lat" => 6.8833f, "lon" => 116.8333f},
                    {"name" => "Semporna", "lat" => 4.4833f, "lon" => 118.6167f},
                    {"name" => "Kunak", "lat" => 4.6333f, "lon" => 118.2500f},
                    {"name" => "Papar", "lat" => 5.7333f, "lon" => 115.9333f},
                    {"name" => "Ranau", "lat" => 5.9500f, "lon" => 116.6833f},
                    {"name" => "Beaufort", "lat" => 5.3500f, "lon" => 115.7500f},
                    {"name" => "Sipitang", "lat" => 5.0833f, "lon" => 115.5500f}
                ];
                
            case "sarawak":
                return [
                    {"name" => "Kuching", "lat" => 1.5533f, "lon" => 110.3592f},
                    {"name" => "Miri", "lat" => 4.3947f, "lon" => 113.9918f},
                    {"name" => "Sibu", "lat" => 2.3000f, "lon" => 111.8167f},
                    {"name" => "Bintulu", "lat" => 3.1667f, "lon" => 113.0333f},
                    {"name" => "Limbang", "lat" => 4.7500f, "lon" => 115.0000f},
                    {"name" => "Sarikei", "lat" => 2.1167f, "lon" => 111.5167f},
                    {"name" => "Sri Aman", "lat" => 1.2333f, "lon" => 111.4667f},
                    {"name" => "Kapit", "lat" => 2.0167f, "lon" => 112.9333f},
                    {"name" => "Samarahan", "lat" => 1.4667f, "lon" => 110.4167f},
                    {"name" => "Betong", "lat" => 1.8667f, "lon" => 111.7667f},
                    {"name" => "Mukah", "lat" => 2.9000f, "lon" => 112.0833f},
                    {"name" => "Lawas", "lat" => 4.8500f, "lon" => 115.4167f}
                ];
                
            case "selangor":
                return [
                    {"name" => "Shah Alam", "lat" => 3.0733f, "lon" => 101.5185f},
                    {"name" => "Petaling Jaya", "lat" => 3.1073f, "lon" => 101.6135f},
                    {"name" => "Subang Jaya", "lat" => 3.0430f, "lon" => 101.5810f},
                    {"name" => "Klang", "lat" => 3.0333f, "lon" => 101.4500f},
                    {"name" => "Kajang", "lat" => 2.9920f, "lon" => 101.7902f},
                    {"name" => "Ampang", "lat" => 3.1500f, "lon" => 101.7667f},
                    {"name" => "Selayang", "lat" => 3.2500f, "lon" => 101.6500f},
                    {"name" => "Rawang", "lat" => 3.3167f, "lon" => 101.5833f},
                    {"name" => "Sepang", "lat" => 2.7333f, "lon" => 101.7000f},
                    {"name" => "Kuala Selangor", "lat" => 3.3333f, "lon" => 101.2500f},
                    {"name" => "Kuala Kubu Bharu", "lat" => 3.5667f, "lon" => 101.6500f},
                    {"name" => "Sabak Bernam", "lat" => 3.8000f, "lon" => 100.9833f}
                ];
                
            case "terengganu":
                return [
                    {"name" => "Kuala Terengganu", "lat" => 5.3302f, "lon" => 103.1408f},
                    {"name" => "Kemaman", "lat" => 4.2333f, "lon" => 103.4333f},
                    {"name" => "Dungun", "lat" => 4.7667f, "lon" => 103.4167f},
                    {"name" => "Marang", "lat" => 5.2167f, "lon" => 103.2167f},
                    {"name" => "Hulu Terengganu", "lat" => 5.1667f, "lon" => 102.9000f},
                    {"name" => "Besut", "lat" => 5.8167f, "lon" => 102.5667f},
                    {"name" => "Setiu", "lat" => 5.6667f, "lon" => 102.8500f}
                ];
                
            case "kl":
                return [
                    {"name" => "Kuala Lumpur City", "lat" => 3.1390f, "lon" => 101.6869f},
                    {"name" => "Cheras", "lat" => 3.1167f, "lon" => 101.7333f},
                    {"name" => "Kepong", "lat" => 3.2167f, "lon" => 101.6333f},
                    {"name" => "Setapak", "lat" => 3.2000f, "lon" => 101.7000f},
                    {"name" => "Wangsa Maju", "lat" => 3.2167f, "lon" => 101.7333f}
                ];
                
            case "putrajaya":
                return [
                    {"name" => "Putrajaya", "lat" => 2.9264f, "lon" => 101.6964f}
                ];
                
            case "labuan":
                return [
                    {"name" => "Labuan", "lat" => 5.2831f, "lon" => 115.2308f}
                ];
                
            default:
                return [];
        }
    }
}
