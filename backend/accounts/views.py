from django.contrib.auth import authenticate
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .models import User
from .serializers import UserSerializer


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    """
    Login endpoint that accepts email/username and password.
    Returns user data and auth token.
    """
    identifier = request.data.get('identifier')  # Can be email or username
    password = request.data.get('password')
    
    if not identifier or not password:
        return Response(
            {'error': 'Please provide both identifier and password'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    # Try to authenticate with email
    user = None
    if '@' in identifier:
        try:
            user_obj = User.objects.get(email=identifier)
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
    
    if user is None:
        return Response(
            {'error': 'Invalid credentials'},
            status=status.HTTP_401_UNAUTHORIZED
        )
    
    # Get or create token
    token, _ = Token.objects.get_or_create(user=user)
    
    return Response({
        'token': token.key,
        'user': UserSerializer(user).data
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def signup_view(request):
    """
    Signup endpoint that creates a new user.
    Returns user data and auth token.
    """
    email = request.data.get('email')
    username = request.data.get('username')
    password = request.data.get('password')
    
    if not email or not username or not password:
        return Response(
            {'error': 'Please provide email, username, and password'},
            status=status.HTTP_400_BAD_REQUEST
        )
    
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
