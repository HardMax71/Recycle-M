"""post photo

Revision ID: d5484920b006
Revises: e1e1ef74333c
Create Date: 2024-07-25 23:13:07.837761

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'd5484920b006'
down_revision: Union[str, None] = 'e1e1ef74333c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.create_table('post_images',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('url', sa.String(), nullable=True),
    sa.Column('post_id', sa.Integer(), nullable=True),
    sa.ForeignKeyConstraint(['post_id'], ['posts.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index(op.f('ix_post_images_id'), 'post_images', ['id'], unique=False)
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_index(op.f('ix_post_images_id'), table_name='post_images')
    op.drop_table('post_images')
    # ### end Alembic commands ###
