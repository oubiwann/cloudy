(defmodule cloudy
  (export all))

(include-lib "deps/erlcloud/include/erlcloud_ec2.hrl")
(include-lib "yaws/include/yaws_api.hrl")

;; Demonstrate creating an instance on Amazon EC2
(defun run-aws-instance (ami)
  (: ssl start)
  (: erlcloud start)
  (let ((instance-config (make-ec2_instance_spec
                           image_id ami)))
    (: erlcloud_ec2 run_instances instance-config)))

;; Demonstrate creating an instance on Rackspace Cloud
(defun run-rax-instance (image-id)
  (let* ((auth-data (: lferax-identity login))
         (region '"DFW")
         (flavors-list (: lferax-servers get-flavors-list
                         auth-data region))
         (flavor-id (: lferax-servers get-id
                      '"30 GB Performance"
                      flavors-list)))
    (: lferax-servers create-server
      auth-data region '"my-new-server"image-id flavor-id)))

;; REST utility functions
(defun parse-path (arg-data)
  "Use the LFE record macros to parse the 'pathinfo' field from the record
  defined in yaws_api.hrl."
  (arg-pathinfo arg-data))

(defun get-http-method (arg-data)
  "Use the LFE record macros to parse the 'req' field from the record defined in
  yaws_api.hrl. This will return the 'http_request' sub-record from which the
  'method' fieild will be returned."
  (let ((record (arg-req arg-data)))
    (http_request-method record)))

(defun make-json-response (data)
  "Simple function used for handing off data to YAWS."
  (tuple 'content
         '"application/json"
         data))

(defun make-json-data-response (data)
  "Simple function used for handing off data to YAWS."
  (make-json-response (++ '"{\"data\": \"" data '"\"}")))

(defun make-json-error-response (error)
  "Simple function used for handing off data to YAWS."
  (make-json-response (++ '"{\"error\": \"" error '"\"}")))

;; YAWS functions
(defun out (arg-data)
  "This function is executed by YAWS. It is the YAWS entry point for our
  RESTful service."
  (let ((method-name (get-http-method arg-data))
        (path-info (: string tokens
                      (parse-path arg-data)
                      '"/")))
    (routes path-info method-name arg-data)))

;; REST API functions
(defun routes
  "Routes for the Volvoshop REST API."
  ;; /order
  (((list '"order") method arg-data)
   (order-api method arg-data))
  ;; /order/:id
  (((list '"order" order-id) method arg-data)
   (order-api method order-id arg-data))
  ;; /orders
  (((list '"orders") method arg-data)
   (orders-api method arg-data))
  ;; /payment/order/:id
  (((list '"payment" '"order" order-id) method arg-data)
   (payment-api method order-id arg-data))
  ;; When nothing matches, do this
  ((path method arg)
    (: io format
      '"Unmatched route!~n Path-info: ~p~n method: ~p~n arg-data: ~p~n~n"
      (list path method arg))
    (make-json-error-response '"Unmatched route.")))

(defun order-api
  "The order API for methods without an order id."
  (('POST arg-data)
   (make-json-data-response '"You made a new order.")))

(defun order-api
  "The order API for methods with an order id."
  (('GET order-id arg-data)
   (make-json-data-response (++ '"You got the status for order "
                                order-id '".")))
  (('PUT order-id arg-data)
   (make-json-data-response (++ '"You updated order " order-id '".")))
  (('DELETE order-id arg-data)
   (make-json-data-response (++ '"You deleted an order " order-id '"."))))

(defun orders-api
  "The orders API."
  (('GET arg-data)
   (make-json-data-response '"You got a list of orders.")))

(defun payment-api
  "The payment API."
  (('GET order-id arg-data)
   (make-json-data-response '"You got the payment status of an order."))
  (('PUT order-id arg-data)
   (make-json-data-response '"You paid for an order.")))
