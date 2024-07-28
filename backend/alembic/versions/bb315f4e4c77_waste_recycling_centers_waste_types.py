"""waste recycling centers + waste types

Revision ID: bb315f4e4c77
Revises: 476dd4047b8a
Create Date: 2024-07-26 17:50:41.109824

"""
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy.sql import table, column

# revision identifiers, used by Alembic.
revision: str = 'bb315f4e4c77'
down_revision: Union[str, None] = '476dd4047b8a'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create new tables
    op.create_table('post_types',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('name', sa.String(), nullable=True),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_post_types_id'), 'post_types', ['id'], unique=False)
    op.create_index(op.f('ix_post_types_name'), 'post_types', ['name'], unique=True)

    op.create_table('product_types',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('name', sa.String(), nullable=True),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_product_types_id'), 'product_types', ['id'], unique=False)
    op.create_index(op.f('ix_product_types_name'), 'product_types', ['name'], unique=True)

    op.create_table('recycling_centers',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('name', sa.String(), nullable=True),
                    sa.Column('address', sa.String(), nullable=True),
                    sa.Column('latitude', sa.Float(), nullable=True),
                    sa.Column('longitude', sa.Float(), nullable=True),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_recycling_centers_id'), 'recycling_centers', ['id'], unique=False)
    op.create_index(op.f('ix_recycling_centers_name'), 'recycling_centers', ['name'], unique=False)

    op.create_table('waste_types',
                    sa.Column('id', sa.Integer(), nullable=False),
                    sa.Column('name', sa.String(), nullable=True),
                    sa.Column('reward_points', sa.Integer(), nullable=True),
                    sa.PrimaryKeyConstraint('id')
                    )
    op.create_index(op.f('ix_waste_types_id'), 'waste_types', ['id'], unique=False)
    op.create_index(op.f('ix_waste_types_name'), 'waste_types', ['name'], unique=True)

    # Use batch operations for altering existing tables
    with op.batch_alter_table('posts') as batch_op:
        batch_op.add_column(sa.Column('post_type_id', sa.Integer(), nullable=True))
        batch_op.create_foreign_key('fk_posts_post_type_id', 'post_types', ['post_type_id'], ['id'])
        batch_op.drop_column('type')

    with op.batch_alter_table('products') as batch_op:
        batch_op.add_column(sa.Column('product_type_id', sa.Integer(), nullable=True))
        batch_op.create_foreign_key('fk_products_product_type_id', 'product_types', ['product_type_id'], ['id'])
        batch_op.drop_column('product_type')

    with op.batch_alter_table('rewards') as batch_op:
        batch_op.add_column(sa.Column('waste_type_id', sa.Integer(), nullable=True))
        batch_op.create_foreign_key('fk_rewards_waste_type_id', 'waste_types', ['waste_type_id'], ['id'])
        batch_op.drop_column('waste_type')

    with op.batch_alter_table('waste_collections') as batch_op:
        batch_op.add_column(sa.Column('waste_type_id', sa.Integer(), nullable=True))
        batch_op.create_foreign_key('fk_waste_collections_waste_type_id', 'waste_types', ['waste_type_id'], ['id'])
        batch_op.drop_column('waste_type')

    # Add initial data
    post_types = table('post_types',
                       column('name', sa.String)
                       )
    op.bulk_insert(post_types,
                   [
                       {'name': 'article'},
                       {'name': 'blog_post'},
                       {'name': 'news'},
                       {'name': 'review'},
                       {'name': 'tutorial'},
                   ]
                   )

    product_types = table('product_types',
                          column('name', sa.String)
                          )
    op.bulk_insert(product_types,
                   [
                       {'name': 'hot_deals'},
                       {'name': 'trending'},
                       {'name': 'normal'},
                       {'name': 'clearance'},
                       {'name': 'new_arrival'},
                   ]
                   )

    recycling_centers = table('recycling_centers',
                              column('name', sa.String),
                              column('address', sa.String),
                              column('latitude', sa.Float),
                              column('longitude', sa.Float)
                              )
    op.bulk_insert(recycling_centers,
                   [
                       {'name': 'Green Recycling Center', 'address': '123 Green St', 'latitude': 40.7128,
                        'longitude': -74.0060},
                       {'name': 'Eco Waste Solutions', 'address': '456 Eco Ave', 'latitude': 40.7282,
                        'longitude': -73.7949},
                       {'name': 'Recycle Now', 'address': '789 Earth Blvd', 'latitude': 40.7489, 'longitude': -73.9680},
                       {'name': 'Clean Planet Recycling', 'address': '101 Clean Rd', 'latitude': 40.7231,
                        'longitude': -73.9442},
                       {'name': 'Sustainable Waste Management', 'address': '202 Sustain St', 'latitude': 40.7589,
                        'longitude': -73.9851},
                   ]
                   )

    waste_types = table('waste_types',
                        column('name', sa.String),
                        column('reward_points', sa.Integer)
                        )
    op.bulk_insert(waste_types,
                   [
                       {'name': 'plastic', 'reward_points': 10},
                       {'name': 'paper', 'reward_points': 5},
                       {'name': 'glass', 'reward_points': 15},
                       {'name': 'metal', 'reward_points': 20},
                       {'name': 'electronic', 'reward_points': 30},
                   ]
                   )


def downgrade() -> None:
    # Use batch operations for altering existing tables
    with op.batch_alter_table('waste_collections') as batch_op:
        batch_op.add_column(sa.Column('waste_type', sa.VARCHAR(length=7), nullable=True))
        batch_op.drop_constraint('fk_waste_collections_waste_type_id', type_='foreignkey')
        batch_op.drop_column('waste_type_id')

    with op.batch_alter_table('rewards') as batch_op:
        batch_op.add_column(sa.Column('waste_type', sa.VARCHAR(length=7), nullable=True))
        batch_op.drop_constraint('fk_rewards_waste_type_id', type_='foreignkey')
        batch_op.drop_column('waste_type_id')

    with op.batch_alter_table('products') as batch_op:
        batch_op.add_column(sa.Column('product_type', sa.VARCHAR(length=9), nullable=True))
        batch_op.drop_constraint('fk_products_product_type_id', type_='foreignkey')
        batch_op.drop_column('product_type_id')

    with op.batch_alter_table('posts') as batch_op:
        batch_op.add_column(sa.Column('type', sa.VARCHAR(length=9), nullable=True))
        batch_op.drop_constraint('fk_posts_post_type_id', type_='foreignkey')
        batch_op.drop_column('post_type_id')

    # Drop new tables
    op.drop_index(op.f('ix_waste_types_name'), table_name='waste_types')
    op.drop_index(op.f('ix_waste_types_id'), table_name='waste_types')
    op.drop_table('waste_types')
    op.drop_index(op.f('ix_recycling_centers_name'), table_name='recycling_centers')
    op.drop_index(op.f('ix_recycling_centers_id'), table_name='recycling_centers')
    op.drop_table('recycling_centers')
    op.drop_index(op.f('ix_product_types_name'), table_name='product_types')
    op.drop_index(op.f('ix_product_types_id'), table_name='product_types')
    op.drop_table('product_types')
    op.drop_index(op.f('ix_post_types_name'), table_name='post_types')
    op.drop_index(op.f('ix_post_types_id'), table_name='post_types')
    op.drop_table('post_types')
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('waste_collections', sa.Column('waste_type', sa.VARCHAR(length=7), nullable=True))
    op.drop_constraint(None, 'waste_collections', type_='foreignkey')
    op.drop_column('waste_collections', 'waste_type_id')
    op.add_column('rewards', sa.Column('waste_type', sa.VARCHAR(length=7), nullable=True))
    op.drop_constraint(None, 'rewards', type_='foreignkey')
    op.drop_column('rewards', 'waste_type_id')
    op.add_column('products', sa.Column('product_type', sa.VARCHAR(length=9), nullable=True))
    op.drop_constraint(None, 'products', type_='foreignkey')
    op.drop_column('products', 'product_type_id')
    op.add_column('posts', sa.Column('type', sa.VARCHAR(length=9), nullable=True))
    op.drop_constraint(None, 'posts', type_='foreignkey')
    op.drop_column('posts', 'post_type_id')
    op.drop_index(op.f('ix_waste_types_name'), table_name='waste_types')
    op.drop_index(op.f('ix_waste_types_id'), table_name='waste_types')
    op.drop_table('waste_types')
    op.drop_index(op.f('ix_recycling_centers_name'), table_name='recycling_centers')
    op.drop_index(op.f('ix_recycling_centers_id'), table_name='recycling_centers')
    op.drop_table('recycling_centers')
    op.drop_index(op.f('ix_product_types_name'), table_name='product_types')
    op.drop_index(op.f('ix_product_types_id'), table_name='product_types')
    op.drop_table('product_types')
    op.drop_index(op.f('ix_post_types_name'), table_name='post_types')
    op.drop_index(op.f('ix_post_types_id'), table_name='post_types')
    op.drop_table('post_types')
    # ### end Alembic commands ###
