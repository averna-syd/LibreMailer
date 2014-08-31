DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id`        INTEGER     AUTO_INCREMENT PRIMARY KEY,
  `username`  VARCHAR(64) NOT NULL UNIQUE KEY,
  `password`  TEXT NOT NULL,
  `firstname` VARCHAR(200) NOT NULL,
  `lastname`  VARCHAR(200) NOT NULL,
  `email`     VARCHAR(200) NOT NULL,
  INDEX (username, email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `id`    INTEGER     AUTO_INCREMENT PRIMARY KEY,
  `role`  VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `user_roles`;
CREATE TABLE `user_roles` (
 `id`       INTEGER     AUTO_INCREMENT PRIMARY KEY,
 `user_id`  INTEGER  NOT NULL,
 `role_id`  INTEGER  NOT NULL,
  UNIQUE KEY user_role (user_id, role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `lists`;
CREATE TABLE `lists` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(200) NOT NULL UNIQUE KEY,
  `description` TEXT NOT NULL,
  INDEX (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `contacts`;
CREATE TABLE `contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `list_id` int(11) NOT NULL DEFAULT 0,
  `email` varchar(200) NOT NULL,
  `format` SET('HTML','Text') DEFAULT 'HTML',
  `confirmation` SET('Confirmed','Unconfirmed') DEFAULT 'Confirmed',
  `status` SET('Active','Unsubscribed','Bounced') DEFAULT 'Active',
  `firstname` TEXT DEFAULT NULL,
  `lastname` TEXT DEFAULT NULL,
  INDEX (list_id, email, confirmation, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `campaigns`;
CREATE TABLE `campaigns` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `name` varchar(64) NOT NULL UNIQUE KEY,
  `list_id` int(11) NOT NULL,
  `email_from` varchar(200) NOT NULL,
  `email_reply_to` varchar(200) NOT NULL,
  `email_bounce_to` varchar(200) NOT NULL,
  `subject` varchar(200) NOT NULL,
  `text_body` TEXT DEFAULT NULL,
  `html_body` TEXT DEFAULT NULL,
  `send` SET('Yes','No') DEFAULT 'No',
  `sending` SET('Yes','No') DEFAULT 'No',
  `sent` SET('Yes','No') DEFAULT 'No',
  `scheduled` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  INDEX (list_id, send, sending, sent)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `url_mappings`;
CREATE TABLE `url_mappings` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `campaign_id` int(11) NOT NULL,
  `name` TEXT DEFAULT NULL,
  `destination` TEXT DEFAULT NULL,
  INDEX (campaign_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics`;
CREATE TABLE `statistics` (
  `id` int(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `campaign_name` varchar(64) NOT NULL UNIQUE KEY,
  `campaign_id` int(11) NOT NULL,
  `list_id` int(11) NOT NULL,
  `start_sending` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `end_sending` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  INDEX (campaign_id, list_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics_recipients`;
CREATE TABLE `statistics_recipients` (
  `campaign_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `email` varchar(200) NOT NULL,
  INDEX (campaign_id, contact_id, email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics_opens`;
CREATE TABLE `statistics_opens` (
  `campaign_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  INDEX (campaign_id, contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics_links`;
CREATE TABLE `statistics_links` (
  `campaign_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  `url_id` int(11) NOT NULL,
  INDEX (campaign_id, contact_id, url_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics_bounces`;
CREATE TABLE `statistics_bounces` (
  `campaign_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  INDEX (campaign_id, contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `statistics_unsubscribes`;
CREATE TABLE `statistics_unsubscribes` (
  `campaign_id` int(11) NOT NULL,
  `contact_id` int(11) NOT NULL,
  INDEX (campaign_id, contact_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO roles (role) value ('Administrator');
INSERT INTO roles (role) value ('Manage Contacts');
INSERT INTO roles (role) value ('Manage Campaigns');
INSERT INTO users (username, password, firstname, lastname, email)
VALUES ('admin', '{CRYPT}$2a$04$f18lR0i.wcRnAKcf/mjVr.TQEZfA6tAyv1raobh48/tAg6bbCwqKe', 'Default', 'Admin', 'admin@localhost');
INSERT INTO user_roles (role_id, user_id) VALUES ('1', '1');
insert into lists (name, description) values ('Default List', 'This is an example contact list.');
insert into contacts (list_id, email, format, confirmation, status, firstname, lastname) values ('1', 'sarah@so-not-real.com', 'HTML', 'Confirmed', 'Active', 'Sarah', 'Fuller');
insert into campaigns (name, list_id, send, email_reply_to, subject, text_body, html_body, scheduled) values ('Example Campaign', '1', 'No', 'sarah@so-not-real.com', 'Example Campaign', 
'
Having trouble viewing this email? Try viewing it online: [% viewonline %]

My Company

Hi [% firstname %],

Google: http://www.google.com/
YouTube: http://www.youtube.com/

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris eu rutrum justo. Fusce massa odio, blandit eu molestie in, commodo a lorem. Cras facilisis mi diam. Sed sit amet auctor magna, sit amet facilisis sapien. Nam fermentum odio eu eros porta, ut fermentum orci maximus. Quisque sem lorem, fermentum et convallis et, consectetur at enim. Sed quis laoreet sapien. Etiam sit amet dolor vitae nulla facilisis egestas varius vel eros. Maecenas blandit, sapien et pulvinar tincidunt, sem nunc pulvinar mauris, id viverra diam velit ut justo. Donec et dapibus augue. Nam ullamcorper est sit amet neque hendrerit accumsan.



unsubscribe: [% unsubscribe %]
',
'
<html>
<body bgcolor="#2D2D2D">
<table width="100%" height="100%" align="center" border="0" cellpadding="0" cellspacing="0" bgcolor="#2D2D2D">
        <tbody>
                <tr>
                        <td valign="top" height="50">
                        <table align="center" border="0" cellpadding="0" cellspacing="0" width="600">
                          <tbody>
                                <tr>
                                        <td valign="top"><font color="#ffffff" face="Helvetica, Arial, sans-serif" size="6">My Company<br></font><br></td>
                                </tr>
                           </tbody>
                          </table>
                        </td>
                </tr>
                <tr>
                        <td valign="top">
                        <table align="center" border="0" cellpadding="40" cellspacing="0" width="600" bgcolor="#ffffff">
                          <tbody>
                                <tr>
                                        <td valign="top">
<p style="text-align: center;"><font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="2">Having trouble viewing this email? Try <a href="[% viewonline %]">viewing it online</a>.</font></p>
<br><br>
<font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="3">Hi [% firstname %],<br><br>

<a href="http://www.google.com/">Google</a>.<br><br>
<a href="http://www.youtube.com/">YouTube</a>.<br><br>

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris eu rutrum justo. Fusce massa odio, blandit eu molestie in, commodo a lorem. Cras facilisis mi diam. Sed sit amet auctor magna, sit amet facilisis sapien. Nam fermentum odio eu eros porta, ut fermentum orci maximus. Quisque sem lorem, fermentum et convallis et, consectetur at enim. Sed quis laoreet sapien. Etiam sit amet dolor vitae nulla facilisis egestas varius vel eros. Maecenas blandit, sapien et pulvinar tincidunt, sem nunc pulvinar mauris, id viverra diam velit ut justo. Donec et dapibus augue. Nam ullamcorper est sit amet neque hendrerit accumsan.</font>
<br><br><br><br><br><br><br><br>
<p style="text-align: center;"><font color="#5a5a5a" face="Helvetica, Arial, sans-serif" size="2"><a href="[% unsubscribe %]">Unsubscribe</a></font></p>
</font></td>
                                </tr>
                           </tbody>
                          </table>
                        <br><br><br><br>
                        </td>
                </tr>
        </tbody>
</table>
</body>
</html>
', '2014-08-29 12:14:36');
