from django.contrib.auth import authenticate, password_validation
from django.core.exceptions import ValidationError
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.response import Response

from .models import User
from .serializers import UserSerializer
from core.models import AppSettings


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([ScopedRateThrottle])
def login_view(request):
    """
    Login endpoint that accepts email/username and password.
    Returns user data and auth token.
    """
    request._request.throttle_scope = "auth_login"

    identifier = (request.data.get('identifier') or '').strip()  # Can be email or username
    password = request.data.get('password') or ''
    
    if not identifier or not password:
        return Response(
            {'error': 'Please provide both identifier and password'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Try to authenticate with email
    user = None
    identifier_lower = identifier.lower()
    if '@' in identifier_lower:
        try:
            user_obj = User.objects.get(email=identifier_lower)
            user = authenticate(request, username=user_obj.email, password=password)
        except User.DoesNotExist:
            pass
    else:
        # Try public_username
        try:
            user_obj = User.objects.get(public_username=identifier)
            user = authenticate(request, username=user_obj.email, password=password)
        except User.DoesNotExist:
            pass

    if user is None or not user.is_active:
        return Response(
            {'error': 'Invalid credentials'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    # Get or create token
    Token.objects.filter(user=user).delete()  # enforce single active token
    token = Token.objects.create(user=user)
    
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data
    })


@api_view(['POST'])
@permission_classes([AllowAny])
@throttle_classes([ScopedRateThrottle])
def signup_view(request):
    """
    Signup endpoint that creates a new user.
    Returns user data and auth token.
    """
    request._request.throttle_scope = "auth_signup"

    email = (request.data.get('email') or '').strip().lower()
    username = (request.data.get('username') or '').strip()
    password = request.data.get('password') or ''
    
    if not email or not username or not password:
        return Response(
            {'error': 'Please provide email, username, and password'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    settings_obj = AppSettings.load()
    if settings_obj and not settings_obj.allow_new_registrations:
        return Response({'error': 'Registrations are temporarily closed'}, status=status.HTTP_403_FORBIDDEN)

    if len(password) < 8:
        return Response({'error': 'Password must be at least 8 characters'}, status=status.HTTP_400_BAD_REQUEST)

    if username and not username.replace('_', '').isalnum():
        return Response({'error': 'Username may contain letters, numbers, and underscore'}, status=status.HTTP_400_BAD_REQUEST)

    # Check if user already exists
    if User.objects.filter(email=email).exists():
        return Response(
            {'error': 'User with this email already exists'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    if User.objects.filter(public_username=username).exists():
        return Response(
            {'error': 'Username already taken'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Validate password against Django validators
    try:
        password_validation.validate_password(password)
    except ValidationError as exc:
        return Response({'error': exc.messages}, status=status.HTTP_400_BAD_REQUEST)

    # Create user
    user = User.objects.create_user(
        email=email,
        password=password,
        public_username=username
    )
    
    # Create token
    token = Token.objects.create(user=user)
    
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data
    }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    """
    Logout endpoint that deletes the user's auth token.
    """
    try:
        request.user.auth_token.delete()
    except Exception:
        pass
    
    return Response({'message': 'Successfully logged out'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_current_user(request):
    """
    Get current authenticated user's data.
    """
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['PATCH'])
@permission_classes([IsAuthenticated])
def update_user_profile(request):
    """
    Update current user's profile data.
    """
    user = request.user
    serializer = UserSerializer(user, data=request.data, partial=True)
    
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    
    print(f"Validation errors: {serializer.errors}")
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# Scoped throttling identifiers for function-based views
login_view.throttle_scope = 'auth_login'
signup_view.throttle_scope = 'auth_signup'
