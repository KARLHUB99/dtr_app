import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceDashboardPage extends StatelessWidget {
  const AttendanceDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Attendance Record',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('View Sanctioned'),
          ),
          TextButton(
            onPressed: () {},
            child: Text('Print'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Filter section
            Row(
              children: [
                Expanded(child: _buildDropdown('Select Program')),
                SizedBox(width: 10),
                Expanded(child: _buildDropdown('Select Year')),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text('View Records'),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Summary cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard('Total Students', '1,525', Colors.blue),
                _buildSummaryCard('Attended', '1,139', Colors.green),
                _buildSummaryCard('Not Attended', '386', Colors.orange),
              ],
            ),
            SizedBox(height: 20),

            // Search section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.search),
                  label: Text('Search'),
                ),
              ],
            ),
            SizedBox(height: 30),

            // Result box
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file, size: 50, color: Colors.grey),
                    Text("No Records Found",
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                    Text("No attendance records match your current filters.",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(),
      ),
      items: [],
      onChanged: (value) {},
    );
  }

  Widget _buildSummaryCard(String title, String count, Color color) {
    return Card(
      elevation: 4,
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(title,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}
