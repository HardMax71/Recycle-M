"""product image

Revision ID: 4a5bc5ef610c
Revises: c0fdd70414af
Create Date: 2024-07-26 11:57:11.033171

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '4a5bc5ef610c'
down_revision: Union[str, None] = 'c0fdd70414af'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.add_column('products', sa.Column('image_url', sa.String(), nullable=True))
    # ### end Alembic commands ###


def downgrade() -> None:
    # ### commands auto generated by Alembic - please adjust! ###
    op.drop_column('products', 'image_url')
    # ### end Alembic commands ###
