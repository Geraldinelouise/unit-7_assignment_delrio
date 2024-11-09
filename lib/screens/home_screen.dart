import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>> fetchItems() async {
    final response = await http
        .get(Uri.parse('https://digi-api.com/api/v1/digimon?pageSize=20'));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data['content']?.cast<Map<String, dynamic>>() ?? [];
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digimon"),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index] as Map<String, dynamic>;
                return buildListTile(context, item);
              },
            );
          } else {
            return const Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  Widget buildListTile(BuildContext context, Map<String, dynamic> item) {
    return ExpansionTile(
      title: Text(item['name'] ?? 'No title'),
      leading: item['image'] != null
          ? Image.network(item['image'],
              width: 50, height: 50, fit: BoxFit.cover)
          : const Icon(Icons.image),
      children: [
        ListTile(
          title: GestureDetector(
            onTap: () async {
              final url = item['href']?.toString();
              if (url != null && url.isNotEmpty) {
                try {
                  final response = await http.get(Uri.parse(url));
                  if (response.statusCode == 200) {
                    final digimonData =
                        jsonDecode(response.body) as Map<String, dynamic>;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DigimonDetailsScreen(digimonData: digimonData),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Failed to fetch digimon details.')),
                    );
                  }
                } catch (e) {
                  print('Error fetching digimon details: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('An unexpected error occurred.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Link not available for this item')),
                );
              }
            },
            child: const Text('Click to learn more about this Digimon'),
          ),
        ),
      ],
    );
  }
}

class DigimonDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> digimonData;

  const DigimonDetailsScreen({super.key, required this.digimonData});

  @override
  Widget build(BuildContext context) {
    final description = digimonData['descriptions']?.firstWhere(
          (desc) => desc['language'] == 'en_us',
          orElse: () => null,
        )?['description'] ??
        'No English description found';

    return Scaffold(
      appBar: AppBar(
        title: Text(digimonData['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${digimonData['id']}'),
            Text('Description (en_us): $description'),
          ],
        ),
      ),
    );
  }
}
