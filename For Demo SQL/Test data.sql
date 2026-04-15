use CA_db.db

INSERT INTO `CA_db`.`ca_customers` (`customer_id`, `prefix`, `firstname`, `surname`, `phone`, `houseNumber`, `streetName`, `postcode`, `credit_limit`) VALUES ('ACC0001', 'Ms', 'Eva', 'Bauyer', '02073218001', '1', 'Liverpool street', 'EC2V 8NS', '500');
INSERT INTO `CA_db`.`ca_customers` (`customer_id`, `prefix`, `firstname`, `surname`, `phone`, `houseNumber`, `streetName`, `postcode`, `credit_limit`) VALUES ('ACC0002', 'Ms', 'Glynne', 'Morisson', '02073218001', '1', 'Liverpool street', 'EC2V 8NS', '500.00');

INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000001', 'Paracetamol', '0.10', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000002', 'Aspirin', '0.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000003', 'Analgin', '1.20', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000004', 'Celebrex, caps 100 mg', '10.00', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000005', 'Celebrex, caps 200 mg', '18.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000006', 'Retin-A Tretin, 30g', '25.00', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000007', 'Lipitor TB, 20mg', '15.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('10000008', 'Claritin CR, 60g', '19.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('20000004', 'Iodine tincture', '0.30', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('20000005', 'Rhynol', '2.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('30000001', 'Ospen', '10.50', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('30000002', 'Amopen', '15.00', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('40000001', 'Vitamin C', '1.20', '0');
INSERT INTO `CA_db`.`ca_products` (`product_id`, `product_name`, `price`, `vat_rate`) VALUES ('40000002', 'Vitamin B12', '1.30', '0');

UPDATE `CA_db`.`ca_products` SET `product_type` = 'Pain Relief', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '20' WHERE (`product_id` = '10000001');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Pain Relief', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '20' WHERE (`product_id` = '10000002');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Pain Relief', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '10' WHERE (`product_id` = '10000003');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Pain Relief', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '10' WHERE (`product_id` = '10000004');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Pain Relief', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '10' WHERE (`product_id` = '10000005');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Skin Treatment', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '20' WHERE (`product_id` = '10000006');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Cholesterol', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '30' WHERE (`product_id` = '10000007');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Antihistamines', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '20' WHERE (`product_id` = '10000008');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Antibiotics', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '20' WHERE (`product_id` = '30000001');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Antibiotics', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '30' WHERE (`product_id` = '30000002');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Vitamins', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '30' WHERE (`product_id` = '40000001');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Vitamins', `package_type` = 'Box', `product_units` = 'Caps', `units_per_pack` = '30' WHERE (`product_id` = '40000002');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Antiseptics', `package_type` = 'Bottle', `product_units` = 'Ml', `units_per_pack` = '100' WHERE (`product_id` = '20000004');
UPDATE `CA_db`.`ca_products` SET `product_type` = 'Respiratory', `package_type` = 'Bottle', `product_units` = 'Ml', `units_per_pack` = '200' WHERE (`product_id` = '20000005');

INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000001', '121', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000002', '201', '15');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000003', '25', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000004', '43', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000005', '35', '5');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000006', '28', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000007', '10', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('10000008', '21', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('20000004', '35', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('20000005', '14', '15');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('30000001', '78', '10');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('30000002', '90', '15');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('40000001', '22', '15');
INSERT INTO `CA_db`.`ca_stock` (`product_id`, `quantity`, `low_stock_threshold`) VALUES ('40000002', '43', '15');


