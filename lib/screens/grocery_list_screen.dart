import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item_model.dart';
import 'package:shopping_list/screens/new_item_screen.dart';
import 'package:http/http.dart' as http;

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('shopping-list-3dd57-default-rtdb.firebaseio.com',
        'shopping-list.json');
    try {
      final response = await http.get(url);

    if (response.statusCode >= 400) {
      setState(() {
        _error = "Failed to fetch data, pleas try again later";
      });
    }

    if (response.body == 'null') {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere((categoryItem) =>
              categoryItem.value.name == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
    } catch (error) {
      setState(() {
        _error = "Something went wrong, please try again later";
      });
    }
    
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (context) => const NewItemScreen(),
      ),
    );

    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https('shopping-list-3dd57-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');

    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete item, please try again',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your groceries',
        ),
        actions: [
          IconButton(
              onPressed: () {
                _addItem();
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _groceryItems.isEmpty
              ? const Center(
                  child: Text(
                    "No Items, try adding one.",
                    style: TextStyle(fontSize: 24),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: TextStyle(fontSize: 24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _groceryItems.length,
                      itemBuilder: (context, index) {
                        final item = _groceryItems[index];
                        return Dismissible(
                          key: ValueKey(item.id),
                          onDismissed: (direction) {
                            _removeItem(item);
                          },
                          child: ListTile(
                            leading: Container(
                              width: 30,
                              height: 30,
                              color: _groceryItems[index].category.color,
                            ),
                            title: Text(
                              _groceryItems[index].name,
                            ),
                            trailing: Text(
                              _groceryItems[index].quantity.toString(),
                              style: const TextStyle(
                                fontSize: 17,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
