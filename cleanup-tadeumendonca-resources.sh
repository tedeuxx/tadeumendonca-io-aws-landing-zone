#!/bin/bash

# Enhanced Targeted AWS Resource Cleanup Script for tadeumendonca.io resources
# This handles dependencies in the correct order

echo "🧹 Starting enhanced cleanup for tadeumendonca.io resources..."

# Set region
AWS_REGION="sa-east-1"
PROJECT_PREFIX="tadeumendonca.io"

echo "📍 Using region: $AWS_REGION"
echo "🎯 Targeting resources with prefix: $PROJECT_PREFIX"

# Function to wait for resource deletion
wait_for_deletion() {
    local resource_type=$1
    local check_command=$2
    echo "    ⏳ Waiting for $resource_type to be deleted..."
    for i in {1..12}; do  # Wait up to 2 minutes
        if ! eval $check_command > /dev/null 2>&1; then
            echo "    ✅ $resource_type deleted"
            return 0
        fi
        echo "    ⏳ Still waiting... ($i/12)"
        sleep 10
    done
    echo "    ⚠️ Timeout waiting for $resource_type deletion"
    return 1
}

# 1. First, release all unattached EIPs
echo "🔧 Step 1: Releasing unattached Elastic IPs..."
aws ec2 describe-addresses --region $AWS_REGION --query 'Addresses[?AssociationId==null].AllocationId' --output text | tr '\t' '\n' | while read allocation_id; do
    if [ ! -z "$allocation_id" ]; then
        echo "  Releasing EIP: $allocation_id"
        aws ec2 release-address --allocation-id $allocation_id --region $AWS_REGION
    fi
done

# 2. Clean up VPCs with proper dependency handling
echo "🔧 Step 2: Cleaning up project VPCs with dependency handling..."
aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=${PROJECT_PREFIX}-vpc" --query 'Vpcs[].VpcId' --output text | tr '\t' '\n' | while read vpc_id; do
    if [ ! -z "$vpc_id" ]; then
        echo "  🎯 Processing VPC: $vpc_id"
        
        # Step 2a: Delete NAT Gateways first (they hold EIPs)
        echo "    🔧 Deleting NAT Gateways..."
        nat_gateways=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[?State==`available`].NatGatewayId' --output text)
        if [ ! -z "$nat_gateways" ]; then
            echo "$nat_gateways" | tr '\t' '\n' | while read nat_id; do
                if [ ! -z "$nat_id" ]; then
                    echo "      Deleting NAT Gateway: $nat_id"
                    aws ec2 delete-nat-gateway --nat-gateway-id $nat_id --region $AWS_REGION
                fi
            done
            
            # Wait for NAT gateways to be deleted
            echo "    ⏳ Waiting for NAT Gateways to be deleted (this takes time)..."
            sleep 60  # NAT gateways take time to delete
            
            # Check if NAT gateways are still deleting
            for i in {1..20}; do  # Wait up to 10 minutes
                remaining=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=vpc-id,Values=$vpc_id" --query 'NatGateways[?State==`deleting` || State==`available`].NatGatewayId' --output text)
                if [ -z "$remaining" ]; then
                    echo "    ✅ All NAT Gateways deleted"
                    break
                fi
                echo "    ⏳ NAT Gateways still deleting... ($i/20)"
                sleep 30
            done
        fi
        
        # Step 2b: Delete EC2 instances in this VPC
        echo "    🔧 Terminating EC2 instances..."
        aws ec2 describe-instances --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" "Name=instance-state-name,Values=running,stopped,stopping" --query 'Reservations[].Instances[].InstanceId' --output text | tr '\t' '\n' | while read instance_id; do
            if [ ! -z "$instance_id" ]; then
                echo "      Terminating instance: $instance_id"
                aws ec2 terminate-instances --instance-ids $instance_id --region $AWS_REGION
            fi
        done
        
        # Step 2c: Delete Load Balancers
        echo "    🔧 Deleting Load Balancers..."
        aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[?VpcId=='$vpc_id'].LoadBalancerArn" --output text | tr '\t' '\n' | while read lb_arn; do
            if [ ! -z "$lb_arn" ]; then
                echo "      Deleting Load Balancer: $lb_arn"
                aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn --region $AWS_REGION
            fi
        done
        
        # Step 2d: Delete Network Interfaces
        echo "    🔧 Deleting Network Interfaces..."
        aws ec2 describe-network-interfaces --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'NetworkInterfaces[?Status==`available`].NetworkInterfaceId' --output text | tr '\t' '\n' | while read eni_id; do
            if [ ! -z "$eni_id" ]; then
                echo "      Deleting Network Interface: $eni_id"
                aws ec2 delete-network-interface --network-interface-id $eni_id --region $AWS_REGION 2>/dev/null || echo "        Failed (may be attached)"
            fi
        done
        
        # Step 2e: Now try to detach and delete Internet Gateways
        echo "    🔧 Detaching Internet Gateways..."
        aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$vpc_id" --query 'InternetGateways[].InternetGatewayId' --output text | tr '\t' '\n' | while read igw_id; do
            if [ ! -z "$igw_id" ]; then
                echo "      Detaching IGW: $igw_id from VPC: $vpc_id"
                aws ec2 detach-internet-gateway --internet-gateway-id $igw_id --vpc-id $vpc_id --region $AWS_REGION 2>/dev/null || echo "        Failed to detach"
                echo "      Deleting IGW: $igw_id"
                aws ec2 delete-internet-gateway --internet-gateway-id $igw_id --region $AWS_REGION 2>/dev/null || echo "        Failed to delete"
            fi
        done
        
        # Step 2f: Delete Route Tables (except main)
        echo "    🔧 Deleting Route Tables..."
        aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text | tr '\t' '\n' | while read rt_id; do
            if [ ! -z "$rt_id" ]; then
                echo "      Deleting Route Table: $rt_id"
                aws ec2 delete-route-table --route-table-id $rt_id --region $AWS_REGION 2>/dev/null || echo "        Failed (may have dependencies)"
            fi
        done
        
        # Step 2g: Delete Security Groups (except default)
        echo "    🔧 Deleting Security Groups..."
        aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
            if [ ! -z "$sg_id" ]; then
                echo "      Deleting Security Group: $sg_id"
                aws ec2 delete-security-group --group-id $sg_id --region $AWS_REGION 2>/dev/null || echo "        Failed (may have dependencies)"
            fi
        done
        
        # Step 2h: Delete Subnets
        echo "    🔧 Deleting Subnets..."
        aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$vpc_id" --query 'Subnets[].SubnetId' --output text | tr '\t' '\n' | while read subnet_id; do
            if [ ! -z "$subnet_id" ]; then
                echo "      Deleting Subnet: $subnet_id"
                aws ec2 delete-subnet --subnet-id $subnet_id --region $AWS_REGION 2>/dev/null || echo "        Failed (may have dependencies)"
            fi
        done
        
        # Step 2i: Finally delete the VPC
        echo "    🔧 Deleting VPC: $vpc_id"
        aws ec2 delete-vpc --vpc-id $vpc_id --region $AWS_REGION 2>/dev/null || echo "      Failed (may still have dependencies)"
    fi
done

# 3. Clean up remaining project resources
echo "🔧 Step 3: Cleaning up remaining project resources..."

# Clean up project-specific IAM Roles
echo "  🔧 Cleaning up IAM Roles..."
aws iam list-roles --query "Roles[?contains(RoleName, '${PROJECT_PREFIX}')].RoleName" --output text | tr '\t' '\n' | while read role_name; do
    if [ ! -z "$role_name" ]; then
        echo "    Deleting IAM Role: $role_name"
        # First detach managed policies
        aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[].PolicyArn' --output text | tr '\t' '\n' | while read policy_arn; do
            if [ ! -z "$policy_arn" ]; then
                aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy_arn" 2>/dev/null
            fi
        done
        # Delete inline policies
        aws iam list-role-policies --role-name "$role_name" --query 'PolicyNames[]' --output text | tr '\t' '\n' | while read policy_name; do
            if [ ! -z "$policy_name" ]; then
                aws iam delete-role-policy --role-name "$role_name" --policy-name "$policy_name" 2>/dev/null
            fi
        done
        # Delete role
        aws iam delete-role --role-name "$role_name" 2>/dev/null || echo "      Failed to delete role"
    fi
done

# Clean up project S3 Buckets
echo "  🔧 Cleaning up S3 Buckets..."
aws s3api list-buckets --query "Buckets[?contains(Name, '${PROJECT_PREFIX}')].Name" --output text | tr '\t' '\n' | while read bucket_name; do
    if [ ! -z "$bucket_name" ]; then
        echo "    Emptying and deleting S3 Bucket: $bucket_name"
        aws s3 rm "s3://$bucket_name" --recursive 2>/dev/null || echo "      Failed to empty"
        aws s3api delete-bucket --bucket "$bucket_name" --region $AWS_REGION 2>/dev/null || echo "      Failed to delete"
    fi
done

# Clean up project DB Subnet Groups
echo "  🔧 Cleaning up DB Subnet Groups..."
aws rds describe-db-subnet-groups --region $AWS_REGION --query "DBSubnetGroups[?contains(DBSubnetGroupName, '${PROJECT_PREFIX}')].DBSubnetGroupName" --output text | tr '\t' '\n' | while read sg_name; do
    if [ ! -z "$sg_name" ]; then
        echo "    Deleting DB Subnet Group: $sg_name"
        aws rds delete-db-subnet-group --db-subnet-group-name "$sg_name" --region $AWS_REGION 2>/dev/null || echo "      Failed to delete"
    fi
done

echo ""
echo "✅ Enhanced cleanup completed!"
echo "⚠️  Some resources may still have dependencies and need manual cleanup."
echo "🔄 You may need to run this script multiple times as dependencies are resolved."
echo "📋 Check AWS Console to verify cleanup and manually delete any remaining resources."
echo ""
echo "💡 If VPCs still can't be deleted, check for:"
echo "   - Running EC2 instances"
echo "   - Load Balancers"
echo "   - RDS instances"
echo "   - Lambda functions with VPC configuration"
echo "   - Network interfaces still attached"