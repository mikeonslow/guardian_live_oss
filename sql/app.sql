-- MySQL dump 10.13  Distrib 5.7.22, for Linux (x86_64)
--
-- Host: localhost    Database: app
-- ------------------------------------------------------
-- Server version	5.7.22-0ubuntu0.16.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `app_permissions`
--

DROP TABLE IF EXISTS `app_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `app_permissions` (
  `nid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vapp_name` varchar(128) NOT NULL,
  `c_permission_sets` text NOT NULL,
  PRIMARY KEY (`nid`),
  UNIQUE KEY `vapp_name` (`vapp_name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `app_permissions`
--

LOCK TABLES `app_permissions` WRITE;
/*!40000 ALTER TABLE `app_permissions` DISABLE KEYS */;
INSERT INTO `app_permissions` VALUES (2,'app','{\"windows\":[\"crash_cpu\",\"BSOD\",\"General Protection Gault\"],\"unix\":[\"r\",\"w\",\"x\",\"d\",\"a\",\"X\"],\"default\":[\"login\",\"token\",\"logout\",\"refresh\",\"exchange\"],\"auth_test\":[\"p1\",\"p3\",\"p4\",\"p5\",\"p2\"],\"admin\":[\"app_permission_sets\",\"app_roles\",\"save_app_perm_sets\",\"save_app_roles\"],\"Billing\":[\"setup\",\"add card\",\"charge\",\"refund\"]}');
/*!40000 ALTER TABLE `app_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `employees`
--

DROP TABLE IF EXISTS `employees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `employees` (
  `iUID` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sUID` varchar(25) NOT NULL DEFAULT '',
  `sName` varchar(25) NOT NULL DEFAULT '',
  `sEmail` varchar(50) NOT NULL DEFAULT '',
  `nroleid` int(10) unsigned NOT NULL DEFAULT '0',
  `password_shadow` text,
  PRIMARY KEY (`iUID`),
  KEY `k_Auth` (`sUID`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `employees`
--

LOCK TABLES `employees` WRITE;
/*!40000 ALTER TABLE `employees` DISABLE KEYS */;
INSERT INTO `employees` VALUES (1,'io','Igor','borodark@gmail.com',1,'$2b$12$59WpK32dx7Qe9ZVzajtlbOb2wAksXXKfMRVdszrG/L4oCmST5jxfi');
/*!40000 ALTER TABLE `employees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `nid` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vname` varchar(50) NOT NULL DEFAULT '0',
  `clperms` text NOT NULL,
  PRIMARY KEY (`nid`)
) ENGINE=InnoDB AUTO_INCREMENT=67 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'Account Manager','{\"unix\":[\"a\",\"d\",\"r\",\"w\",\"x\"],\"default\":[\"exchange\",\"login\",\"logout\",\"refresh\",\"token\"],\"admin\":[\"app_permission_sets\",\"app_roles\",\"save_app_perm_sets\",\"save_app_roles\"]}'),(40,'Full Access','{\"default\":[\"exchange\",\"login\",\"logout\",\"refresh\",\"token\"]}'),(55,'brand new role','{\"windows\":[\"General Protection Gault\",\"BSOD\"],\"unix\":[\"r\",\"w\",\"x\"],\"default\":[\"exchange\",\"login\",\"logout\",\"refresh\",\"token\"],\"admin\":[\"app_permission_sets\",\"app_roles\",\"save_app_perm_sets\",\"save_app_roles\"],\"Billing\":[\"add card\",\"charge\",\"refund\",\"setup\"]}');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2018-06-27 22:40:59
