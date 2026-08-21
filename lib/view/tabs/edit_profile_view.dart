import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:equate/viewmodel/theme_viewmodel.dart'; // Sesuaikan path jika berbeda

class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  // Controller untuk Form Input
  final TextEditingController _nicknameController = TextEditingController(text: 'Vina');
  final TextEditingController _fullNameController = TextEditingController(text: 'Vina Dwi Maulita');
  final TextEditingController _emailController = TextEditingController(text: 'vina@equate.com');
  final TextEditingController _dobController = TextEditingController(text: '07/04/2002');

  DateTime? _selectedDate = DateTime(2002, 4, 7);

  @override
  void dispose() {
    _nicknameController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Fungsi Pemilih Tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF9800),
              onPrimary: Colors.white,
              onSurface: ThemeViewModel.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeViewModel.isDarkMode;

    const primaryOrange = Color(0xFFFF9800);
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardBgColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.grey[50];
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final inputBorderColor = isDarkMode ? Colors.grey[800]! : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(
            color: primaryTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Profil & Tombol Ubah
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: const NetworkImage('https://i.pravatar.cc/300?img=5'),
                          backgroundColor: Colors.grey[300],
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: primaryOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        // TODO: Logika ganti foto profil
                      },
                      child: Text(
                        'Ubah Foto Profil',
                        style: GoogleFonts.poppins(
                          color: primaryOrange,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Form Input: Nama Panggilan
              _buildInputField(
                label: 'Nama Panggilan',
                controller: _nicknameController,
                icon: Icons.badge_outlined,
                isDarkMode: isDarkMode,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                inputBorderColor: inputBorderColor,
                cardBgColor: cardBgColor,
              ),

              const SizedBox(height: 16),

              // Form Input: Nama Lengkap
              _buildInputField(
                label: 'Nama Lengkap',
                controller: _fullNameController,
                icon: Icons.person_outline_rounded,
                isDarkMode: isDarkMode,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                inputBorderColor: inputBorderColor,
                cardBgColor: cardBgColor,
              ),

              const SizedBox(height: 16),

              // Form Input: Email
              _buildInputField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                isDarkMode: isDarkMode,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                inputBorderColor: inputBorderColor,
                cardBgColor: cardBgColor,
              ),

              const SizedBox(height: 16),

              // Form Input: Tanggal Lahir (Dengan Date Picker)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Lahir',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dobController,
                        style: GoogleFonts.poppins(color: primaryTextColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'DD/MM/YYYY',
                          hintStyle: GoogleFonts.poppins(color: secondaryTextColor, fontSize: 13),
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: secondaryTextColor, size: 20),
                          filled: true,
                          fillColor: cardBgColor,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: inputBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: inputBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryOrange, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Logika simpan profil
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Profil berhasil diperbarui!', style: GoogleFonts.poppins()),
                        backgroundColor: primaryOrange,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Simpan Perubahan',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget untuk Field Input standar
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required Color inputBorderColor,
    required Color? cardBgColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primaryTextColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(color: primaryTextColor, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: secondaryTextColor, size: 20),
            filled: true,
            fillColor: cardBgColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFFF9800), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}