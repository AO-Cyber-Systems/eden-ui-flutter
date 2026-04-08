import 'package:flutter/material.dart';

/// Status values for a support ticket.
enum SupportTicketStatus { open, inProgress, waiting, resolved, closed }

/// Priority levels for a support ticket.
enum SupportTicketPriority { low, normal, high, urgent }

/// A help-center article.
class SupportArticle {
  const SupportArticle({
    required this.id,
    required this.title,
    required this.viewCount,
    required this.helpfulCount,
    this.slug,
    this.body,
    this.status,
    this.categoryId,
  });

  final String id;
  final String title;
  final String? slug;
  final String? body;
  final String? status;
  final String? categoryId;
  final int viewCount;
  final int helpfulCount;
}

/// A category grouping help articles.
class SupportCategory {
  const SupportCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.slug,
    this.parentId,
  });

  final String id;
  final String name;
  final String? slug;
  final String? parentId;
  final int sortOrder;
}

/// A support ticket submitted by a user.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    required this.priority,
    required this.tags,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String subject;
  final String? description;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

/// A comment on a support ticket.
class SupportComment {
  const SupportComment({
    required this.id,
    required this.ticketId,
    required this.body,
    this.createdAt,
  });

  final String id;
  final String ticketId;
  final String body;
  final DateTime? createdAt;
}

/// A product-tour definition linking showcase steps to GlobalKeys.
class EdenTourDefinition {
  const EdenTourDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.steps,
    required this.isCompleted,
    this.icon,
  });

  final String id;
  final String title;
  final String description;
  final List<GlobalKey> steps;
  final IconData? icon;
  final bool isCompleted;
}
