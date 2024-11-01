import 'package:flutter/material.dart';

class Product {
  final int id;
  final String isbn;
  final String title;
  final String author;
  final String publicationYear;
  final String publisher;
  final String? suppliers;

  Product({ 
    required this.id,
    required this.isbn,
    required this.title,
    required this.author,
    required this.publicationYear,
    required this.publisher,
    this.suppliers
  });

  factory Product.fromJSON(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      isbn: json['isbn'],
      title: json['title'],
      author: json['author'],
      publicationYear: json['publication_year'],
      publisher: json['publisher'],
      suppliers: json['suppliers']
    );
  }

}