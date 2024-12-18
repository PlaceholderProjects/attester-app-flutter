import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reown_appkit/reown_appkit.dart';

import '../utils/constants.dart';


class SessionItem extends StatelessWidget {
  const SessionItem({
    required Key key,
    required this.session,
  }) : super(key: key);

  final SessionData session;

  @override
  Widget build(BuildContext context) {
    final expiryTimestamp = DateTime.fromMillisecondsSinceEpoch(
      session.expiry * 1000,
    );
    final dateFormat = DateFormat.yMd().add_jm();
    final expiryDate = dateFormat.format(expiryTimestamp);
    final inDays = expiryTimestamp.difference(DateTime.now()).inDays + 1;
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.peer.metadata.name,
            style: StyleConstants.paragraph,
          ),
          Text('Expiry: $expiryDate ($inDays days)'),
        ],
      ),
    );
  }
}
