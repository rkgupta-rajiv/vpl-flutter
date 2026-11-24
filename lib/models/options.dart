/// Option lists — keys MUST match the Laravel backend (App\Models\Player).
class Options {
  static const genders = {'male': 'Male', 'female': 'Female', 'other': 'Other'};
  static const roles = {
    'batsman': 'Batsman',
    'bowler': 'Bowler',
    'all_rounder': 'All-Rounder',
    'wicket_keeper': 'Wicket Keeper',
  };
  static const batting = {'right': 'Right Hand', 'left': 'Left Hand'};
  static const bowling = {'right_arm': 'Right Arm', 'left_arm': 'Left Arm', 'na': 'Not Applicable'};
  static const tshirt = {'S': 'S', 'M': 'M', 'L': 'L', 'XL': 'XL', 'XXL': 'XXL', 'XXXL': 'XXXL'};
  static const documents = {
    'photo': 'Profile Photo',
    'aadhaar_front': 'Aadhaar Card – Front',
    'aadhaar_back': 'Aadhaar Card – Back',
  };

  static String label(Map<String, String> map, String? key) => key == null ? '—' : (map[key] ?? key);
}
