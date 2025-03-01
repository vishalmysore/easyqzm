import 'package:easyqzm/service/api_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../model/link.dart';

class TrendingLinksTab extends StatefulWidget {
  @override
  TrendingLinksTabState createState() => TrendingLinksTabState();
}

class TrendingLinksTabState extends State<TrendingLinksTab> {
  late Future<List<Link>> _trendingLinksFuture;
  bool _showLastHour = true; // Toggle state

  @override
  void initState() {
    super.initState();
    _fetchLinks();
  }

  void _fetchLinks() {
    setState(() {
      _trendingLinksFuture = _showLastHour
          ? ApiService().getTrendingLastHour()
          : ApiService().getTrendingLastAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle Switch
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Trending Last Hour", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Switch(
                value: !_showLastHour,
                onChanged: (value) {
                  setState(() {
                    _showLastHour = !value;
                    _fetchLinks();
                  });
                },
              ),
              Text("Trending All Time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        // Trending Links Table
        Expanded(
          child: FutureBuilder<List<Link>>(
            future: _trendingLinksFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error fetching trending links"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No trending links available"));
              } else {
                List<Link> links = snapshot.data!;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20.0,
                    columns: [
                      DataColumn(label: Text('URL', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Author', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Access Count', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Keywords', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: links.map((link) {
                      return DataRow(
                        cells: [
                          DataCell(
                            InkWell(
                              child: Text(link.url, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                              onTap: () => launchUrl(Uri.parse(link.url)),
                            ),
                          ),
                          DataCell(Text(link.author)),
                          DataCell(Text(link.totalAccessCount.toString())),
                          DataCell(Text(link.keywords != null ? link.keywords!.split(',').join(', ') : "N/A")),
                        ],
                      );
                    }).toList(),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
