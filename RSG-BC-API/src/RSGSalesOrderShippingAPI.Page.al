// =============================================================================
//  RSG Sales Order Shipping API  (Page 50200)
// -----------------------------------------------------------------------------
//  Exposes the Shipping & Billing fields from the Sales Header table that the
//  standard salesOrders v2.0 API does NOT surface (package tracking, shipping
//  agent, location, shipment date, shipping advice, etc.).
//
//  Keyed on SystemId, so the "id" here is the SAME GUID as the standard
//  salesOrders entity: read an order from salesOrders, take its id, then
//  GET/PATCH salesOrderShipping(<id>) for these fields.
//
//  Endpoint:
//    .../api/radiant/salesFulfillment/v1.0/companies({companyId})/salesOrderShipping
//
//  Scope: unposted sales ORDERS only. CRUD: read + update (PATCH); insert and
//  delete disabled so the endpoint can't create or remove orders.
// =============================================================================
page 50200 "RSG Sales Order Shipping API"
{
    PageType = API;
    Caption = 'RSG Sales Order Shipping API';
    APIPublisher = 'radiant';
    APIGroup = 'salesFulfillment';
    APIVersion = 'v1.0';
    EntityName = 'salesOrderShipping';
    EntitySetName = 'salesOrderShipping';
    SourceTable = "Sales Header";
    SourceTableView = where("Document Type" = const(Order));
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(records)
            {
                // ---- Identity / correlation ----
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(number; Rec."No.")
                {
                    Caption = 'No.';
                    Editable = false;
                }
                field(sellToCustomerNumber; Rec."Sell-to Customer No.")
                {
                    Caption = 'Sell-to Customer No.';
                    Editable = false;
                }
                field(billToCustomerNumber; Rec."Bill-to Customer No.")
                {
                    Caption = 'Bill-to Customer No.';
                    Editable = false;
                }

                // ---- Dates ----
                field(orderDate; Rec."Order Date")
                {
                    Caption = 'Order Date';
                }
                field(shipmentDate; Rec."Shipment Date")
                {
                    Caption = 'Shipment Date';
                }
                field(requestedDeliveryDate; Rec."Requested Delivery Date")
                {
                    Caption = 'Requested Delivery Date';
                }
                field(promisedDeliveryDate; Rec."Promised Delivery Date")
                {
                    Caption = 'Promised Delivery Date';
                }

                // ---- Location & method ----
                field(locationCode; Rec."Location Code")
                {
                    Caption = 'Location Code';
                }
                field(shipmentMethodCode; Rec."Shipment Method Code")
                {
                    Caption = 'Shipment Method Code';
                }

                // ---- Shipping agent / tracking ----
                field(shippingAgentCode; Rec."Shipping Agent Code")
                {
                    Caption = 'Shipping Agent Code';
                }
                field(shippingAgentServiceCode; Rec."Shipping Agent Service Code")
                {
                    Caption = 'Shipping Agent Service Code';
                }
                field(packageTrackingNumber; Rec."Package Tracking No.")
                {
                    Caption = 'Package Tracking No.';
                }

                // ---- Shipping behavior ----
                field(shippingAdvice; Rec."Shipping Advice")
                {
                    Caption = 'Shipping Advice';
                }
                field(combineShipments; Rec."Combine Shipments")
                {
                    Caption = 'Combine Shipments';
                }
                field(outboundWhseHandlingTime; Rec."Outbound Whse. Handling Time")
                {
                    Caption = 'Outbound Whse. Handling Time';
                }
                field(shippingTime; Rec."Shipping Time")
                {
                    Caption = 'Shipping Time';
                }

                // ---- Calculated status (read-only FlowFields) ----
                field(lateOrderShipping; Rec."Late Order Shipping")
                {
                    Caption = 'Late Order Shipping';
                    Editable = false;
                }
                field(completelyShipped; Rec."Completely Shipped")
                {
                    Caption = 'Completely Shipped';
                    Editable = false;
                }

                // ========================================================
                //  CUSTOM / EXTENSION FIELDS (marketplace / F3 connector)
                //  Amazon Shipment Id, F3 Synced by Connector, and Actual
                //  Shipping Cost are NOT standard Sales Header fields. To
                //  expose them: confirm the field names from that extension,
                //  add it to "dependencies" in app.json, then uncomment:
                //
                //  field(amazonShipmentId; Rec."Amazon Shipment Id") { }
                //  field(syncedByConnector; Rec."F3 Synced by Connector") { Editable = false; }
                //  field(actualShippingCost; Rec."Actual Shipping Cost") { }
                // ========================================================
            }
        }
    }
}
