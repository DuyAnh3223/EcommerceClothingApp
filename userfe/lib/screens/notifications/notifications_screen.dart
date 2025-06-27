import 'package:flutter/material.dart';
import 'package:userfe/services/notification_service.dart';
import 'package:userfe/services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  int currentPage = 1;
  int totalPages = 1;
  String? selectedType;
  bool? selectedReadStatus;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getUserData();
    if (data != null) {
      setState(() {
        userData = data;
      });
      await _loadNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (userData == null) return;

    if (refresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
      });
    } else {
      setState(() {
        isLoadingMore = true;
      });
    }

    final result = await NotificationService.getNotifications(
      userId: userData!['id'],
      page: currentPage,
      type: selectedType,
      isRead: selectedReadStatus,
    );

    if (mounted) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        final newNotifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        
        if (refresh) {
          notifications = newNotifications;
        } else {
          notifications.addAll(newNotifications);
        }
        
        if (data['pagination'] != null) {
          totalPages = data['pagination']['total_pages'] ?? 1;
        }
      } else {
        if (refresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Lỗi tải thông báo'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    if (userData == null) return;

    final result = await NotificationService.markAsRead(
      userId: userData!['id'],
      notificationId: notificationId,
    );

    if (result['success'] == true) {
      // Update local state
      setState(() {
        final index = notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          notifications[index]['is_read'] = true;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (userData == null) return;

    final result = await NotificationService.markAsRead(
      userId: userData!['id'],
      markAll: true,
    );

    if (result['success'] == true) {
      setState(() {
        for (var notification in notifications) {
          notification['is_read'] = true;
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lọc thông báo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Type filter
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Loại thông báo',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: 'order_status', child: Text('Trạng thái đơn hàng')),
                DropdownMenuItem(value: 'sale', child: Text('Khuyến mãi')),
                DropdownMenuItem(value: 'voucher', child: Text('Voucher')),
                DropdownMenuItem(value: 'other', child: Text('Khác')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedType = value;
                });
              },
            ),
            const SizedBox(height: 16),
            // Read status filter
            DropdownButtonFormField<bool?>(
              value: selectedReadStatus,
              decoration: const InputDecoration(
                labelText: 'Trạng thái đọc',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Tất cả')),
                DropdownMenuItem(value: false, child: Text('Chưa đọc')),
                DropdownMenuItem(value: true, child: Text('Đã đọc')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedReadStatus = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNotifications(refresh: true);
            },
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'order_status':
        return 'Trạng thái đơn hàng';
      case 'sale':
        return 'Khuyến mãi';
      case 'voucher':
        return 'Voucher';
      case 'other':
        return 'Khác';
      default:
        return type;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'order_status':
        return Icons.shopping_bag;
      case 'sale':
        return Icons.local_offer;
      case 'voucher':
        return Icons.card_giftcard;
      case 'other':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'order_status':
        return Colors.blue;
      case 'sale':
        return Colors.orange;
      case 'voucher':
        return Colors.green;
      case 'other':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} ngày trước';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ trước';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút trước';
      } else {
        return 'Vừa xong';
      }
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (notifications.any((n) => !n['is_read']))
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: _markAllAsRead,
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có thông báo nào',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(refresh: true),
                  child: ListView.builder(
                    itemCount: notifications.length + (currentPage < totalPages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == notifications.length) {
                        // Load more indicator
                        if (!isLoadingMore) {
                          _loadMoreNotifications();
                        }
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final notification = notifications[index];
                      final isRead = notification['is_read'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: isRead ? null : Colors.blue.shade50,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getTypeColor(notification['type']).withOpacity(0.2),
                            child: Icon(
                              _getTypeIcon(notification['type']),
                              color: _getTypeColor(notification['type']),
                            ),
                          ),
                          title: Text(
                            notification['title'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (notification['content'] != null)
                                Text(
                                  notification['content'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getTypeColor(notification['type']).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _getTypeText(notification['type']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getTypeColor(notification['type']),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(notification['created_at']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: !isRead
                              ? IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () => _markAsRead(notification['id']),
                                  tooltip: 'Đánh dấu đã đọc',
                                )
                              : null,
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(notification['id']);
                            }
                            // TODO: Navigate to relevant screen based on notification type
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _loadMoreNotifications() {
    if (currentPage < totalPages && !isLoadingMore) {
      setState(() {
        currentPage++;
      });
      _loadNotifications();
    }
  }
} 