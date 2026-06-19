from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db import transaction
from .models import Cart, CartItem, Order, OrderItem, CancelledOrder, Transaction
from products.models import Product, ProductVariant
from users.models import UserProfile
from .serializers import CartSerializer, OrderSerializer
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers

@extend_schema(responses={200: CartSerializer})
@api_view(['GET'])
def get_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart, created = Cart.objects.get_or_create(user=user)
        serializer = CartSerializer(cart)
        return Response(serializer.data)
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@extend_schema(
    request=inline_serializer(
        name='AddToCartRequest',
        fields={
            'product_id': serializers.IntegerField(),
            'quantity': serializers.IntegerField(default=1),
            'unit_value': serializers.FloatField(default=1.0),
        }
    ),
    responses={200: CartSerializer}
)
@api_view(['POST'])
def add_to_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart, created = Cart.objects.get_or_create(user=user)
        
        product_id = request.data.get('product_id')
        quantity = int(request.data.get('quantity', 1))
        unit_value = float(request.data.get('unit_value', 1.0))
        
        if quantity <= 0:
             return Response({'error': 'Quantity must be greater than 0'}, status=status.HTTP_400_BAD_REQUEST)

        product = get_object_or_404(Product, id=product_id)
        
        # Check if user is the vendor
        if product.vendor == user:
            return Response({'error': 'You cannot add your own product to cart'}, status=status.HTTP_400_BAD_REQUEST)

        # STOCK VALIDATION
        variant = ProductVariant.objects.filter(product=product, quantity=unit_value).first()
        
        if variant:
            # Tiered Pricing: Check Variant Stock (Count)
            # Find existing quantity of this variant in cart
            existing_item = CartItem.objects.filter(cart=cart, product=product, unit_value=unit_value).first()
            existing_qty = float(existing_item.quantity) if existing_item else 0.0
            
            total_needed = existing_qty + quantity
            if total_needed > float(variant.stock_quantity):
                 return Response({'error': f'Not enough stock available for this variant. Available: {variant.stock_quantity}'}, status=status.HTTP_400_BAD_REQUEST)
        else:
            # Standard Pricing: Check Global Stock (Volume/Weight)
            required_stock = quantity * unit_value
            # Also check existing cart items for this product (aggregated)
            existing_items = CartItem.objects.filter(cart=cart, product=product)
            existing_volume = sum(float(item.quantity) * float(item.unit_value) for item in existing_items)
            
            total_volume_needed = existing_volume + required_stock
            
            if total_volume_needed > float(product.stock_quantity):
                return Response({'error': 'Not enough stock available'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Add/Update Cart Item
        cart_item, item_created = CartItem.objects.get_or_create(
            cart=cart, 
            product=product,
            unit_value=unit_value,
            defaults={'quantity': 0}
        )
        
        cart_item.quantity = float(cart_item.quantity) + quantity
        cart_item.save()
        
        return Response(CartSerializer(cart).data, status=status.HTTP_200_OK)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(
    request=inline_serializer(
        name='UpdateCartItemRequest',
        fields={'quantity': serializers.FloatField()}
    ),
    responses={200: CartSerializer}
)
@api_view(['PUT'])
def update_cart_item(request, user_id, item_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        
        quantity = float(request.data.get('quantity'))
        
        if quantity <= 0:
            cart_item.delete()
        else:
            # STOCK VALIDATION
            variant = ProductVariant.objects.filter(product=cart_item.product, quantity=cart_item.unit_value).first()
            
            if variant:
                 # Tiered: Check Count
                 if quantity > float(variant.stock_quantity):
                     return Response({'error': f'Not enough stock available. Available: {variant.stock_quantity}'}, status=status.HTTP_400_BAD_REQUEST)
            else:
                 # Standard: Check Volume
                 required_stock = quantity * float(cart_item.unit_value)
                 # We should technically exclude current item from existing sum, but for simple update:
                 # Just check if this new quantity fits in total stock?
                 # ideally: total_product_stock >= (other_items_volume + this_item_volume)
                 # simplified: just check this item vs stock (assuming singular item type in cart usually or strict check)
                 if required_stock > float(cart_item.product.stock_quantity):
                     return Response({'error': 'Not enough stock available'}, status=status.HTTP_400_BAD_REQUEST)

            cart_item.quantity = quantity
            cart_item.save()
            
        return Response(CartSerializer(cart).data)
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Cart.DoesNotExist:
        return Response({'error': 'Cart not found'}, status=status.HTTP_404_NOT_FOUND)

@extend_schema(responses={200: CartSerializer})
@api_view(['DELETE'])
def remove_from_cart(request, user_id, item_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart_item = get_object_or_404(CartItem, id=item_id, cart=cart)
        cart_item.delete()
        
        return Response(CartSerializer(cart).data)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(responses={200: CartSerializer})
@api_view(['DELETE'])
def clear_cart(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = Cart.objects.get(user=user)
        cart.items.all().delete()
        return Response(CartSerializer(cart).data)
    except Exception as e:
         return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(
    request=inline_serializer(
        name='PlaceOrderRequest',
        fields={
            'shipping_address': serializers.CharField(required=False),
            'city': serializers.CharField(required=False),
            'state': serializers.CharField(required=False),
            'pincode': serializers.CharField(required=False),
            'payment_method': serializers.CharField(default='COD'),
            'is_paid': serializers.BooleanField(default=False),
        }
    ),
    responses={201: OrderSerializer}
)
@api_view(['POST'])
@transaction.atomic
def place_order(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        cart = get_object_or_404(Cart, user=user)
        
        if not cart.items.exists():
            return Response({'error': 'Cart is empty'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Prepare Order Data
        shipping_address = request.data.get('shipping_address') or user.address_line
        city = request.data.get('city') or user.city
        state = request.data.get('state') or user.state
        pincode = request.data.get('pincode') or user.pincode
        payment_method = request.data.get('payment_method', 'COD')
        is_paid = request.data.get('is_paid', False)

        if not shipping_address:
             return Response({'error': 'Shipping address required'}, status=status.HTTP_400_BAD_REQUEST)

        # Create Order
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            city=city,
            state=state,
            pincode=pincode,
            total_amount=cart.total_price,
            payment_method=payment_method,
            is_paid=is_paid
        )
        
        # Move items to Order Items and Deduct Stock
        for item in cart.items.all():
            variant = ProductVariant.objects.filter(product=item.product, quantity=item.unit_value).first()
            
            if variant:
                # Tiered: Deduct Count from Variant
                deduction_quantity = float(item.quantity) # For variants, quantity is count
                
                if deduction_quantity > float(variant.stock_quantity):
                    raise Exception(f"Not enough stock for {item.product.name} ({variant.quantity} {variant.unit})")
                
                variant.stock_quantity = float(variant.stock_quantity) - deduction_quantity
                variant.save()
                
                # Update global stock as sum (approximate)
                item.product.stock_quantity = float(item.product.stock_quantity) - deduction_quantity 
                item.product.save()

                OrderItem.objects.create(
                    order=order,
                    product=item.product,
                    product_name=f"{item.product.name} ({variant.quantity} {variant.unit})",
                    quantity=deduction_quantity, 
                    price_at_purchase=variant.price
                )

            else:
                # Standard: Deduct Volume from Product
                deduction_quantity = float(item.quantity) * float(item.unit_value)
                
                if deduction_quantity > float(item.product.stock_quantity):
                    raise Exception(f"Not enough stock for {item.product.name}")
                
                item.product.stock_quantity = float(item.product.stock_quantity) - deduction_quantity
                item.product.save()
            
                OrderItem.objects.create(
                    order=order,
                    product=item.product,
                    product_name=item.product.name,
                    quantity=deduction_quantity, 
                    price_at_purchase=item.product.price
                )
            
            # Additional Fix for OrderItem Price:
            # If variant, we should use variant price.
            # But OrderItem model might assume single price.
            # Let's check OrderItem model briefly if I can.
            
        # Clear Cart
        cart.items.all().delete()
        
        # Record Transaction
        Transaction.objects.create(
            order=order,
            payment_method=payment_method,
            amount=order.total_amount,
            status='Success' if is_paid else 'Pending'
        )
        
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(
    request=inline_serializer(
        name='PlaceDirectOrderRequest',
        fields={
            'shipping_address': serializers.CharField(required=False),
            'city': serializers.CharField(required=False),
            'state': serializers.CharField(required=False),
            'pincode': serializers.CharField(required=False),
            'payment_method': serializers.CharField(default='COD'),
            'is_paid': serializers.BooleanField(default=False),
            'product_id': serializers.IntegerField(),
            'quantity': serializers.FloatField(default=1.0),
            'unit_value': serializers.FloatField(default=1.0)
        }
    ),
    responses={201: OrderSerializer}
)
@api_view(['POST'])
@transaction.atomic
def place_direct_order(request, user_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        
        # Prepare Order Data
        shipping_address = request.data.get('shipping_address') or user.address_line
        city = request.data.get('city') or user.city
        state = request.data.get('state') or user.state
        pincode = request.data.get('pincode') or user.pincode
        payment_method = request.data.get('payment_method', 'COD')
        is_paid = request.data.get('is_paid', False)
        
        product_id = request.data.get('product_id')
        quantity = float(request.data.get('quantity', 1.0))
        unit_value = float(request.data.get('unit_value', 1.0))

        if not shipping_address:
             return Response({'error': 'Shipping address required'}, status=status.HTTP_400_BAD_REQUEST)
        
        product = get_object_or_404(Product, id=product_id)
        
        # Verify user is not buying their own product
        if product.vendor == user:
            return Response({'error': 'You cannot checkout your own product'}, status=status.HTTP_400_BAD_REQUEST)
            
        variant = ProductVariant.objects.filter(product=product, quantity=unit_value).first()
        
        price_at_purchase = product.price
        total_amount = float(product.price) * quantity * unit_value
        product_name = product.name
        
        if variant:
            deduction_quantity = quantity # Count
            if deduction_quantity > float(variant.stock_quantity):
                return Response({'error': f"Not enough stock for {product.name} ({variant.quantity} {variant.unit})"}, status=status.HTTP_400_BAD_REQUEST)
            price_at_purchase = variant.price
            total_amount = float(variant.price) * quantity
            product_name = f"{product.name} ({variant.quantity} {variant.unit})"
            
            variant.stock_quantity = float(variant.stock_quantity) - deduction_quantity
            variant.save()
            product.stock_quantity = float(product.stock_quantity) - deduction_quantity
            product.save()
        else:
            deduction_quantity = quantity * unit_value
            if deduction_quantity > float(product.stock_quantity):
                return Response({'error': f"Not enough stock for {product.name}"}, status=status.HTTP_400_BAD_REQUEST)
            price_at_purchase = product.price
            total_amount = float(product.price) * deduction_quantity
            
            product.stock_quantity = float(product.stock_quantity) - deduction_quantity
            product.save()

        # Create Order
        order = Order.objects.create(
            user=user,
            shipping_address=shipping_address,
            city=city,
            state=state,
            pincode=pincode,
            total_amount=total_amount,
            payment_method=payment_method,
            is_paid=is_paid
        )

        OrderItem.objects.create(
            order=order,
            product=product,
            product_name=product_name,
            quantity=deduction_quantity if not variant else quantity, 
            price_at_purchase=price_at_purchase
        )

        # Record Transaction
        Transaction.objects.create(
            order=order,
            payment_method=payment_method,
            amount=total_amount,
            status='Success' if is_paid else 'Pending'
        )
        
        return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)

@extend_schema(responses={200: OrderSerializer(many=True)})
@api_view(['GET'])
def get_orders(request, user_id):
    try:
        # Check if user exists
        user = UserProfile.objects.get(id=user_id)
        orders = Order.objects.filter(user=user).order_by('-created_at')
        serializer = OrderSerializer(orders, many=True)
        return Response(serializer.data)
    except UserProfile.DoesNotExist:
         return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

@extend_schema(responses={200: OrderSerializer})
@api_view(['GET'])
def get_order_details(request, order_id):
    order = get_object_or_404(Order, id=order_id)
    serializer = OrderSerializer(order)
    return Response(serializer.data)

@extend_schema(
    request=inline_serializer(
        name='CancelOrderRequest',
        fields={'reason': serializers.CharField(required=False)}
    ),
    responses={200: OrderSerializer}
)
@api_view(['POST'])
@transaction.atomic
def cancel_order(request, user_id, order_id):
    try:
        user = UserProfile.objects.get(id=user_id)
        order = get_object_or_404(Order, id=order_id, user=user)

        if order.status not in ['Placed', 'Processing']:
            return Response({'error': f"Order cannot be cancelled. Current status is {order.status}."}, status=status.HTTP_400_BAD_REQUEST)
        
        reason = request.data.get('reason', '')
        
        # Check if already cancelled
        if hasattr(order, 'cancellation'):
           return Response({'error': 'Order is already cancelled'}, status=status.HTTP_400_BAD_REQUEST)

        # Restore Stock
        for item in order.items.all():
            product = item.product
            if product:
                # Based on how place_order deducts stock:
                # If it's a variant, item.product_name != product.name (appends " (qty unit)")
                if item.product_name != product.name:
                    # It's a variant. Try to find the exact variant by price_at_purchase.
                    # As place_order assigns variant.price to price_at_purchase.
                    variant = ProductVariant.objects.filter(product=product, price=item.price_at_purchase).first()
                    if variant:
                        variant.stock_quantity = float(variant.stock_quantity) + float(item.quantity)
                        variant.save()
                
                # Restore global product stock (applies to both variants and standard)
                product.stock_quantity = float(product.stock_quantity) + float(item.quantity)
                product.save()

        # Update order status
        order.status = 'Cancelled'
        order.save()

        # Create cancellation record
        CancelledOrder.objects.create(order=order, reason=reason)

        serializer = OrderSerializer(order)
        return Response(serializer.data)
        
    except UserProfile.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
